/// The reused signals that personalize an interview, flattened to primitives so
/// the repository stays pure and free of other features' model types.
///
/// The controller assembles this from **core providers** (profile, resume
/// analysis, CV draft) + the optional job passed via navigation — everything is
/// optional, so an interview still runs with nothing available.
class InterviewContext {
  const InterviewContext({
    this.role = '',
    this.candidateName = '',
    this.headline = '',
    this.experienceLevel = '',
    this.skills = const [],
    this.resumeSummary = '',
    this.resumeStrengths = const [],
    this.resumeWeaknesses = const [],
    this.resumeMissingSkills = const [],
    this.cvExperiences = const [],
    this.jobTitle = '',
    this.jobRequiredSkills = const [],
    this.country = '',
  });

  /// Resolved target role the interview practises for.
  final String role;

  /// The candidate's location context (Qatar by default) — lets the model tune
  /// examples/expectations to the region.
  final String country;

  // Profile
  final String candidateName;
  final String headline;
  final String experienceLevel;
  final List<String> skills;

  // Resume analysis
  final String resumeSummary;
  final List<String> resumeStrengths;
  final List<String> resumeWeaknesses;
  final List<String> resumeMissingSkills;

  // CV (e.g. "Senior Flutter Engineer — Northwind Apps")
  final List<String> cvExperiences;

  // Job (when started from a specific job)
  final String jobTitle;
  final List<String> jobRequiredSkills;

  /// True when at least one reuse source contributed — drives the "Tailored to…"
  /// hint on the setup screen.
  bool get hasPersonalization =>
      skills.isNotEmpty ||
      resumeSummary.isNotEmpty ||
      resumeStrengths.isNotEmpty ||
      cvExperiences.isNotEmpty ||
      jobTitle.isNotEmpty;
}
