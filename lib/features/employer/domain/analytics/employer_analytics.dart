import 'package:equatable/equatable.dart';

import '../job_status.dart';

/// At-a-glance hiring KPIs for the analytics overview.
class OverviewKpis extends Equatable {
  const OverviewKpis({
    this.totalJobs = 0,
    this.activeJobs = 0,
    this.totalApplicants = 0,
    this.interviews = 0,
    this.hires = 0,
    this.avgMatchScore = 0,
  });

  final int totalJobs;
  final int activeJobs;
  final int totalApplicants;

  /// Applicants who ever reached the interview stage.
  final int interviews;

  /// Applicants with an accepted decision.
  final int hires;

  /// Mean AI match score across applicants that carry one (0 when none do).
  final int avgMatchScore;

  /// Applicant → hire conversion in `[0, 1]`.
  double get hireRate => totalApplicants == 0 ? 0 : hires / totalApplicants;

  @override
  List<Object?> get props =>
      [totalJobs, activeJobs, totalApplicants, interviews, hires, avgMatchScore];
}

/// The application status funnel: how many applicants **reached** each stage
/// (monotonically decreasing: `applied ≥ reviewed ≥ interview ≥ accepted`).
/// [rejected] is off-funnel — the count currently in a rejected state.
class StatusFunnel extends Equatable {
  const StatusFunnel({
    this.applied = 0,
    this.reviewed = 0,
    this.interview = 0,
    this.accepted = 0,
    this.rejected = 0,
  });

  final int applied;
  final int reviewed;
  final int interview;
  final int accepted;
  final int rejected;

  bool get isEmpty => applied == 0;

  static double _rate(int n, int d) => d == 0 ? 0 : n / d;

  // Share of all applicants (funnel-width) — each in `[0, 1]`.
  double get reviewedShare => _rate(reviewed, applied);
  double get interviewShare => _rate(interview, applied);
  double get acceptedShare => _rate(accepted, applied);

  // Stage-to-stage conversion — each in `[0, 1]`.
  double get appliedToReviewed => _rate(reviewed, applied);
  double get reviewedToInterview => _rate(interview, reviewed);
  double get interviewToHire => _rate(accepted, interview);

  @override
  List<Object?> get props => [applied, reviewed, interview, accepted, rejected];
}

/// One job's recruiting performance (for the "top jobs" list).
class JobPerformance extends Equatable {
  const JobPerformance({
    required this.jobId,
    required this.jobTitle,
    required this.status,
    required this.applicants,
    required this.funnel,
  });

  final String jobId;
  final String jobTitle;

  /// The posting's lifecycle status, or `null` when the job is only referenced
  /// by applications and isn't in the employer's current job list (so the UI
  /// shows no — potentially misleading — status chip).
  final JobStatus? status;
  final int applicants;
  final StatusFunnel funnel;

  int get hires => funnel.accepted;
  int get interviews => funnel.interview;

  /// Applicant → hire conversion in `[0, 1]`.
  double get conversion => applicants == 0 ? 0 : hires / applicants;

  @override
  List<Object?> get props => [jobId, jobTitle, status, applicants, funnel];
}

/// Time-to-hire metrics, all in **days** (fractional).
class TimeToHire extends Equatable {
  const TimeToHire({
    this.avgDaysToHire = 0,
    this.medianDaysToHire = 0,
    this.fastestDaysToHire,
    this.hiresConsidered = 0,
    this.avgDaysInPipeline = 0,
    this.openApplicants = 0,
  });

  final double avgDaysToHire;
  final double medianDaysToHire;

  /// Shortest single hire (null when there are no hires).
  final double? fastestDaysToHire;

  /// Number of accepted applicants the averages are computed from.
  final int hiresConsidered;

  /// Mean age (days since applying) of still-open (non-terminal) applicants.
  final double avgDaysInPipeline;
  final int openApplicants;

  bool get hasHires => hiresConsidered > 0;
  bool get hasOpen => openApplicants > 0;

  @override
  List<Object?> get props => [
        avgDaysToHire,
        medianDaysToHire,
        fastestDaysToHire,
        hiresConsidered,
        avgDaysInPipeline,
        openApplicants,
      ];
}

/// Applicant match-score band. [fromScore] buckets 0–100.
enum MatchBand {
  strong,
  good,
  fair,
  weak;

  static MatchBand fromScore(int score) {
    if (score >= 80) return MatchBand.strong;
    if (score >= 60) return MatchBand.good;
    if (score >= 40) return MatchBand.fair;
    return MatchBand.weak;
  }
}

/// Count of applicants in one [MatchBand].
class MatchBandCount extends Equatable {
  const MatchBandCount({required this.band, required this.count});

  final MatchBand band;
  final int count;

  @override
  List<Object?> get props => [band, count];
}

/// A skill and how many applicants list it.
class SkillDemand extends Equatable {
  const SkillDemand({required this.skill, required this.count});

  final String skill;
  final int count;

  @override
  List<Object?> get props => [skill, count];
}

/// Distribution of applicant quality (AI match + resume ATS + top skills).
class ApplicantQuality extends Equatable {
  const ApplicantQuality({
    this.avgMatchScore = 0,
    this.avgAtsScore = 0,
    this.withMatchCount = 0,
    this.withResumeCount = 0,
    this.totalApplicants = 0,
    this.bands = const [],
    this.topSkills = const [],
  });

  final int avgMatchScore;
  final int avgAtsScore;
  final int withMatchCount;
  final int withResumeCount;
  final int totalApplicants;

  /// Always the four bands in order (strong → weak); zero counts included.
  final List<MatchBandCount> bands;

  /// Most-demanded applicant skills, highest first.
  final List<SkillDemand> topSkills;

  bool get hasMatchData => withMatchCount > 0;
  bool get hasResumeData => withResumeCount > 0;
  bool get hasSkills => topSkills.isNotEmpty;

  @override
  List<Object?> get props => [
        avgMatchScore,
        avgAtsScore,
        withMatchCount,
        withResumeCount,
        totalApplicants,
        bands,
        topSkills,
      ];
}

/// Applications received in one weekly window.
class TrendPoint extends Equatable {
  const TrendPoint({required this.weekStart, required this.count});

  /// The first day of the 7-day window (date-only).
  final DateTime weekStart;
  final int count;

  @override
  List<Object?> get props => [weekStart, count];
}

/// Recent recruiting activity — a weekly applications trend plus quick counts.
class ActivityTrend extends Equatable {
  const ActivityTrend({
    this.points = const [],
    this.applicationsLast7Days = 0,
    this.actionsLast7Days = 0,
    this.totalActions = 0,
  });

  /// Weekly application counts, oldest → newest.
  final List<TrendPoint> points;
  final int applicationsLast7Days;

  /// Recruiter actions (status changes / notes) logged in the last 7 days.
  final int actionsLast7Days;
  final int totalActions;

  int get maxCount =>
      points.fold(0, (m, p) => p.count > m ? p.count : m);

  bool get hasActivity =>
      points.any((p) => p.count > 0) || totalActions > 0;

  @override
  List<Object?> get props =>
      [points, applicationsLast7Days, actionsLast7Days, totalActions];
}

/// The complete, computed analytics snapshot for one employer. Derived live from
/// the employer's jobs + applicants + activity streams (see `AnalyticsCalculator`);
/// purely a read model, so it carries no persistence — the AI insights over it are
/// what get cached (Firestore-ready) through `RecruiterInsightsStore`.
class EmployerAnalytics extends Equatable {
  const EmployerAnalytics({
    this.overview = const OverviewKpis(),
    this.funnel = const StatusFunnel(),
    this.jobPerformance = const [],
    this.timeToHire = const TimeToHire(),
    this.quality = const ApplicantQuality(),
    this.trend = const ActivityTrend(),
  });

  final OverviewKpis overview;
  final StatusFunnel funnel;

  /// All jobs (with ≥ 1 applicant or currently live), sorted by applicants desc.
  final List<JobPerformance> jobPerformance;
  final TimeToHire timeToHire;
  final ApplicantQuality quality;
  final ActivityTrend trend;

  static const EmployerAnalytics empty = EmployerAnalytics();

  bool get hasApplicants => overview.totalApplicants > 0;
  bool get hasJobs => overview.totalJobs > 0;

  @override
  List<Object?> get props =>
      [overview, funnel, jobPerformance, timeToHire, quality, trend];
}
