import 'package:equatable/equatable.dart';

/// A trimmed job reference the insights prompt reasons over — primitives only, so
/// the repository never sees the analytics/model types directly.
class InsightJob extends Equatable {
  const InsightJob({
    required this.title,
    this.applicants = 0,
    this.interviews = 0,
    this.hires = 0,
  });

  final String title;
  final int applicants;
  final int interviews;
  final int hires;

  @override
  List<Object?> get props => [title, applicants, interviews, hires];
}

/// The analytics signals that ground the AI "Recruiter Insights" pass, flattened
/// to primitives so the repository stays pure and free of other model types
/// (mirrors `RecommendationContext`). The controller assembles this from
/// [EmployerAnalytics] via **core/feature providers only**.
class RecruiterInsightsContext extends Equatable {
  const RecruiterInsightsContext({
    this.companyName = '',
    this.totalJobs = 0,
    this.activeJobs = 0,
    this.totalApplicants = 0,
    this.applied = 0,
    this.reviewed = 0,
    this.interview = 0,
    this.accepted = 0,
    this.rejected = 0,
    this.hireRatePercent = 0,
    this.interviewRatePercent = 0,
    this.avgMatchScore = 0,
    this.avgAtsScore = 0,
    this.strongMatchCount = 0,
    this.weakMatchCount = 0,
    this.avgDaysToHire = 0,
    this.openApplicants = 0,
    this.avgDaysInPipeline = 0,
    this.applicationsLast7Days = 0,
    this.topJobs = const [],
    this.topSkills = const [],
  });

  final String companyName;

  // Volume
  final int totalJobs;
  final int activeJobs;
  final int totalApplicants;

  // Funnel
  final int applied;
  final int reviewed;
  final int interview;
  final int accepted;
  final int rejected;
  final int hireRatePercent;
  final int interviewRatePercent;

  // Quality
  final int avgMatchScore;
  final int avgAtsScore;
  final int strongMatchCount;
  final int weakMatchCount;

  // Velocity
  final int avgDaysToHire;
  final int openApplicants;
  final int avgDaysInPipeline;

  // Recency + breakdowns
  final int applicationsLast7Days;
  final List<InsightJob> topJobs;
  final List<String> topSkills;

  /// True when there is at least one applicant to reason about.
  bool get hasData => totalApplicants > 0;

  /// A stable fingerprint of the analytics that feed the prompt. Two contexts
  /// with the same signature would produce equivalent insights, so a refresh can
  /// skip the AI call when this matches the cached result.
  String get signature {
    final parts = <String>[
      companyName.trim().toLowerCase(),
      '$totalJobs|$activeJobs|$totalApplicants',
      '$applied|$reviewed|$interview|$accepted|$rejected',
      '$hireRatePercent|$interviewRatePercent',
      '$avgMatchScore|$avgAtsScore|$strongMatchCount|$weakMatchCount',
      '$avgDaysToHire|$openApplicants|$avgDaysInPipeline',
      '$applicationsLast7Days',
      [
        for (final j in topJobs)
          '${j.title.trim().toLowerCase()}:${j.applicants}:${j.interviews}:${j.hires}'
      ].join(','),
      (topSkills.map((s) => s.trim().toLowerCase()).toList()..sort()).join(','),
    ];
    return parts.join('¦');
  }

  @override
  List<Object?> get props => [
        companyName,
        totalJobs,
        activeJobs,
        totalApplicants,
        applied,
        reviewed,
        interview,
        accepted,
        rejected,
        hireRatePercent,
        interviewRatePercent,
        avgMatchScore,
        avgAtsScore,
        strongMatchCount,
        weakMatchCount,
        avgDaysToHire,
        openApplicants,
        avgDaysInPipeline,
        applicationsLast7Days,
        topJobs,
        topSkills,
      ];
}
