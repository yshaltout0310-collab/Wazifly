import '../../../../shared/models/application.dart';
import '../../../../shared/models/employer_activity.dart';
import '../../../../shared/models/job_posting.dart';
import '../job_status.dart';
import 'employer_analytics.dart';

/// Pure, Flutter-free computation of [EmployerAnalytics] from the raw employer
/// data (jobs + applicants + activity). Deterministic and fully unit-testable —
/// the injected [now] anchors every time-relative metric (mirrors the pattern of
/// `JobValidator` and the analytics/recommendations clock seam).
abstract final class AnalyticsCalculator {
  AnalyticsCalculator._();

  /// Number of weekly buckets in the applications trend.
  static const int trendWeeks = 6;

  /// Maximum skills returned in the applicant-quality demand list.
  static const int topSkillsMax = 8;

  static EmployerAnalytics compute({
    required List<JobPosting> jobs,
    required List<Application> applicants,
    List<EmployerActivity> activity = const [],
    required DateTime now,
  }) {
    // Soft-deleted jobs are retained in Firestore but excluded from analytics
    // (the employer streams already filter them; this is defensive).
    final liveJobs = jobs.where((j) => !j.isDeleted).toList();

    final overview = _overview(liveJobs, applicants);
    final funnel = _funnelFor(applicants);
    final jobPerformance = _jobPerformance(liveJobs, applicants);
    final timeToHire = _timeToHire(applicants, now);
    final quality = _quality(applicants, overview.avgMatchScore);
    final trend = _trend(applicants, activity, now);

    return EmployerAnalytics(
      overview: overview,
      funnel: funnel,
      jobPerformance: jobPerformance,
      timeToHire: timeToHire,
      quality: quality,
      trend: trend,
    );
  }

  // --- Overview ---

  static OverviewKpis _overview(
      List<JobPosting> liveJobs, List<Application> applicants) {
    final funnel = _funnelFor(applicants);
    final matched = [
      for (final a in applicants)
        if (a.applicant?.matchScore != null) a.applicant!.matchScore!,
    ];
    return OverviewKpis(
      totalJobs: liveJobs.length,
      activeJobs:
          liveJobs.where((j) => j.status == JobStatus.published).length,
      totalApplicants: applicants.length,
      interviews: funnel.interview,
      hires: funnel.accepted,
      avgMatchScore: _avg(matched),
    );
  }

  // --- Funnel ---

  static StatusFunnel _funnelFor(List<Application> apps) {
    var reviewed = 0, interview = 0, accepted = 0, rejected = 0;
    for (final a in apps) {
      final rank = _funnelRank(a);
      if (rank >= 1) reviewed++;
      if (rank >= 2) interview++;
      if (rank >= 3) accepted++;
      if (a.status == ApplicationStatus.rejected) rejected++;
    }
    return StatusFunnel(
      applied: apps.length,
      reviewed: reviewed,
      interview: interview,
      accepted: accepted,
      rejected: rejected,
    );
  }

  /// The deepest funnel stage an application reached (across current status +
  /// history): 0 pending · 1 reviewed · 2 interview · 3 accepted. A rejection
  /// does not itself advance the rank (the applicant's prior progress, captured
  /// in [Application.history], still counts).
  static int _funnelRank(Application a) {
    var rank = _stageOf(a.status);
    for (final e in a.history) {
      final r = _stageOf(e.status);
      if (r > rank) rank = r;
    }
    return rank;
  }

  static int _stageOf(ApplicationStatus s) => switch (s) {
        ApplicationStatus.pending => 0,
        ApplicationStatus.reviewed => 1,
        ApplicationStatus.interview => 2,
        ApplicationStatus.accepted => 3,
        ApplicationStatus.rejected => 0,
      };

  // --- Per-job performance ---

  static List<JobPerformance> _jobPerformance(
      List<JobPosting> liveJobs, List<Application> applicants) {
    final byJob = <String, List<Application>>{};
    for (final a in applicants) {
      byJob.putIfAbsent(a.jobId, () => []).add(a);
    }
    final titles = {for (final j in liveJobs) j.id: j.title};
    final statuses = {for (final j in liveJobs) j.id: j.status};

    // Union of known jobs and any job referenced by an application (so a job
    // present only in seeded applications still appears).
    final ids = <String>{...liveJobs.map((j) => j.id), ...byJob.keys};

    final list = <JobPerformance>[];
    for (final id in ids) {
      final apps = byJob[id] ?? const <Application>[];
      final knownTitle = titles[id];
      final title = (knownTitle != null && knownTitle.isNotEmpty)
          ? knownTitle
          : (apps.isNotEmpty ? apps.first.jobTitle : '');
      list.add(JobPerformance(
        jobId: id,
        jobTitle: title,
        status: statuses[id], // null when only referenced by applications
        applicants: apps.length,
        funnel: _funnelFor(apps),
      ));
    }
    list.sort((a, b) {
      final byCount = b.applicants.compareTo(a.applicants);
      if (byCount != 0) return byCount;
      return a.jobTitle.toLowerCase().compareTo(b.jobTitle.toLowerCase());
    });
    return List.unmodifiable(list);
  }

  // --- Time to hire ---

  static TimeToHire _timeToHire(List<Application> applicants, DateTime now) {
    final daysToHire = <double>[];
    for (final a in applicants) {
      if (a.status != ApplicationStatus.accepted) continue;
      final acceptedAt = _acceptedAt(a);
      if (acceptedAt == null) continue;
      final days = acceptedAt.difference(a.appliedAt).inMinutes / 1440.0;
      if (days >= 0) daysToHire.add(days);
    }
    daysToHire.sort();

    final pipelineDays = <double>[];
    var open = 0;
    for (final a in applicants) {
      if (_isTerminal(a.status)) continue;
      open++;
      final days = now.difference(a.appliedAt).inMinutes / 1440.0;
      if (days >= 0) pipelineDays.add(days);
    }

    return TimeToHire(
      avgDaysToHire: _avgD(daysToHire),
      medianDaysToHire: _median(daysToHire),
      fastestDaysToHire: daysToHire.isEmpty ? null : daysToHire.first,
      hiresConsidered: daysToHire.length,
      avgDaysInPipeline: _avgD(pipelineDays),
      openApplicants: open,
    );
  }

  /// When the applicant was accepted: the last accepted history event, else the
  /// update time if they currently sit in accepted.
  static DateTime? _acceptedAt(Application a) {
    DateTime? at;
    for (final e in a.history) {
      if (e.status == ApplicationStatus.accepted) at = e.at;
    }
    if (at != null) return at;
    return a.status == ApplicationStatus.accepted ? a.updatedAt : null;
  }

  static bool _isTerminal(ApplicationStatus s) =>
      s == ApplicationStatus.accepted || s == ApplicationStatus.rejected;

  // --- Applicant quality ---

  static ApplicantQuality _quality(
      List<Application> applicants, int avgMatch) {
    final atsScores = [
      for (final a in applicants)
        if (a.applicant?.atsScore != null) a.applicant!.atsScore!,
    ];
    final matchScores = [
      for (final a in applicants)
        if (a.applicant?.matchScore != null) a.applicant!.matchScore!,
    ];

    final bandCounts = {for (final b in MatchBand.values) b: 0};
    for (final s in matchScores) {
      final band = MatchBand.fromScore(s);
      bandCounts[band] = bandCounts[band]! + 1;
    }
    final bands = [
      for (final b in MatchBand.values)
        MatchBandCount(band: b, count: bandCounts[b]!),
    ];

    // Skill demand: count each skill once per applicant (case-insensitive),
    // preserving the first-seen label for display.
    final agg = <String, ({String label, int count})>{};
    for (final a in applicants) {
      final seen = <String>{};
      for (final raw in a.applicant?.skills ?? const <String>[]) {
        final label = raw.trim();
        if (label.isEmpty) continue;
        final key = label.toLowerCase();
        if (!seen.add(key)) continue;
        final cur = agg[key];
        agg[key] = (label: cur?.label ?? label, count: (cur?.count ?? 0) + 1);
      }
    }
    final topSkills = agg.values
        .map((v) => SkillDemand(skill: v.label, count: v.count))
        .toList()
      ..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        if (byCount != 0) return byCount;
        return a.skill.toLowerCase().compareTo(b.skill.toLowerCase());
      });

    return ApplicantQuality(
      avgMatchScore: avgMatch,
      avgAtsScore: _avg(atsScores),
      withMatchCount: matchScores.length,
      withResumeCount: atsScores.length,
      totalApplicants: applicants.length,
      bands: bands,
      topSkills: List.unmodifiable(topSkills.take(topSkillsMax)),
    );
  }

  // --- Activity trend ---

  static ActivityTrend _trend(
    List<Application> applicants,
    List<EmployerActivity> activity,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final counts = List<int>.filled(trendWeeks, 0);
    for (final a in applicants) {
      final day = DateTime(
          a.appliedAt.year, a.appliedAt.month, a.appliedAt.day);
      final daysAgo = today.difference(day).inDays;
      final weeksAgo = daysAgo < 0 ? 0 : daysAgo ~/ 7;
      if (weeksAgo < trendWeeks) counts[trendWeeks - 1 - weeksAgo]++;
    }
    final points = <TrendPoint>[
      for (var b = 0; b < trendWeeks; b++)
        TrendPoint(
          weekStart:
              today.subtract(Duration(days: (trendWeeks - 1 - b) * 7 + 6)),
          count: counts[b],
        ),
    ];

    final weekAgo = now.subtract(const Duration(days: 7));
    final appsLast7 =
        applicants.where((a) => !a.appliedAt.isBefore(weekAgo)).length;
    final actionsLast7 =
        activity.where((e) => !e.at.isBefore(weekAgo)).length;

    return ActivityTrend(
      points: points,
      applicationsLast7Days: appsLast7,
      actionsLast7Days: actionsLast7,
      totalActions: activity.length,
    );
  }

  // --- helpers ---

  static int _avg(List<int> xs) =>
      xs.isEmpty ? 0 : (xs.reduce((a, b) => a + b) / xs.length).round();

  static double _avgD(List<double> xs) =>
      xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;

  /// Median of an **ascending-sorted** list (0 when empty).
  static double _median(List<double> sortedAsc) {
    if (sortedAsc.isEmpty) return 0;
    final n = sortedAsc.length;
    final mid = n ~/ 2;
    return n.isOdd
        ? sortedAsc[mid]
        : (sortedAsc[mid - 1] + sortedAsc[mid]) / 2;
  }
}
