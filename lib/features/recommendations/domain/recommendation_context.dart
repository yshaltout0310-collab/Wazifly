import 'package:equatable/equatable.dart';

/// A trimmed job reference the model recommends *from* — primitives only, so the
/// repository never sees the shared `Job` model. The controller maps real jobs
/// into these.
class AvailableJob extends Equatable {
  const AvailableJob({
    required this.id,
    required this.title,
    this.company = '',
    this.seniority = '',
    this.location = '',
    this.remote = false,
    this.requiredSkills = const [],
  });

  final String id;
  final String title;
  final String company;
  final String seniority;
  final String location;
  final bool remote;
  final List<String> requiredSkills;

  @override
  List<Object?> get props =>
      [id, title, company, seniority, location, remote, requiredSkills];
}

/// The reused signals that personalize the "For You" recommendations, flattened
/// to primitives so the repository stays pure and free of other features' model
/// types. The controller assembles this from **core providers** (profile, resume
/// analysis, CV draft, applications, interviews, saved + available jobs) —
/// everything is optional, so recommendations still generate with little data.
class RecommendationContext extends Equatable {
  const RecommendationContext({
    this.candidateName = '',
    this.headline = '',
    this.location = '',
    this.experienceLevel = '',
    this.skills = const [],
    this.preferredTitles = const [],
    this.profileCompletion = 0,
    this.hasLinks = false,
    this.resumeSummary = '',
    this.resumeStrengths = const [],
    this.resumeWeaknesses = const [],
    this.resumeMissingSkills = const [],
    this.atsScore = 0,
    this.cvTargetRole = '',
    this.cvExperiences = const [],
    this.cvSkills = const [],
    this.appliedCount = 0,
    this.savedCount = 0,
    this.interviewsReached = 0,
    this.offers = 0,
    this.appliedTitles = const [],
    this.savedTitles = const [],
    this.interviewCount = 0,
    this.avgInterviewScore = 0,
    this.weakestDimension = '',
    this.typesPracticed = const [],
    this.availableJobs = const [],
    this.appliedJobIds = const {},
  });

  // Profile
  final String candidateName;
  final String headline;
  final String location;
  final String experienceLevel;
  final List<String> skills;
  final List<String> preferredTitles;
  final int profileCompletion;
  final bool hasLinks;

  // Resume analysis
  final String resumeSummary;
  final List<String> resumeStrengths;
  final List<String> resumeWeaknesses;
  final List<String> resumeMissingSkills;
  final int atsScore;

  // CV
  final String cvTargetRole;
  final List<String> cvExperiences; // "Role — Company"
  final List<String> cvSkills;

  // Applications activity
  final int appliedCount;
  final int savedCount;
  final int interviewsReached;
  final int offers;
  final List<String> appliedTitles;
  final List<String> savedTitles;

  // Interview practice
  final int interviewCount;
  final int avgInterviewScore;
  final String weakestDimension;
  final List<String> typesPracticed;

  // Jobs universe (recommend from these) + exclusion set.
  final List<AvailableJob> availableJobs;
  final Set<String> appliedJobIds;

  /// The union of every skill we know about the candidate.
  List<String> get allSkills =>
      <String>{...skills, ...cvSkills}.toList(growable: false);

  /// True when at least one meaningful signal contributed — drives the
  /// "let's get to know you" nudge vs. a fully personalized plan.
  bool get hasSignal =>
      allSkills.isNotEmpty ||
      resumeSummary.isNotEmpty ||
      cvExperiences.isNotEmpty ||
      preferredTitles.isNotEmpty ||
      appliedCount > 0 ||
      interviewCount > 0;

  /// A stable fingerprint of the user data that feeds the prompt. Two contexts
  /// with the same signature would produce equivalent recommendations, so a
  /// refresh can skip the AI call when this matches the cached result. The
  /// static jobs universe is intentionally excluded; the applied-jobs set (which
  /// changes what gets recommended) is included.
  String get signature {
    List<String> sorted(List<String> xs) =>
        (xs.map((e) => e.trim().toLowerCase()).toList()..sort());
    final parts = <String>[
      candidateName.trim().toLowerCase(),
      headline.trim().toLowerCase(),
      location.trim().toLowerCase(),
      experienceLevel,
      sorted(skills).join(','),
      sorted(preferredTitles).join(','),
      '$profileCompletion',
      hasLinks ? '1' : '0',
      resumeSummary.trim().toLowerCase(),
      sorted(resumeStrengths).join(','),
      sorted(resumeWeaknesses).join(','),
      sorted(resumeMissingSkills).join(','),
      '$atsScore',
      cvTargetRole.trim().toLowerCase(),
      sorted(cvExperiences).join(','),
      sorted(cvSkills).join(','),
      '$appliedCount|$savedCount|$interviewsReached|$offers',
      sorted(appliedTitles).join(','),
      sorted(savedTitles).join(','),
      '$interviewCount|$avgInterviewScore|$weakestDimension',
      sorted(typesPracticed).join(','),
      sorted(appliedJobIds.toList()).join(','),
    ];
    return parts.join('¦');
  }

  @override
  List<Object?> get props => [
        candidateName,
        headline,
        location,
        experienceLevel,
        skills,
        preferredTitles,
        profileCompletion,
        hasLinks,
        resumeSummary,
        resumeStrengths,
        resumeWeaknesses,
        resumeMissingSkills,
        atsScore,
        cvTargetRole,
        cvExperiences,
        cvSkills,
        appliedCount,
        savedCount,
        interviewsReached,
        offers,
        appliedTitles,
        savedTitles,
        interviewCount,
        avgInterviewScore,
        weakestDimension,
        typesPracticed,
        availableJobs,
        appliedJobIds,
      ];
}
