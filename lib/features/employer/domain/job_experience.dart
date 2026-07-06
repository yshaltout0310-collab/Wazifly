/// Required experience level of a job posting.
///
/// [canonical] maps to the seeker `Job.seniority` string (matching the seed
/// dataset's "Junior"/"Mid"/"Senior"/"Lead"), so the projected public job is
/// consistent with what the seeker platform already renders. A job-scoped enum
/// (not the profile feature's `ExperienceLevel`) to avoid an employer→profile
/// dependency.
enum JobExperience {
  entry,
  junior,
  mid,
  senior,
  lead;

  String get canonical => switch (this) {
        JobExperience.entry => 'Entry',
        JobExperience.junior => 'Junior',
        JobExperience.mid => 'Mid',
        JobExperience.senior => 'Senior',
        JobExperience.lead => 'Lead',
      };

  static JobExperience? fromName(Object? value) {
    if (value is! String) return null;
    final v = value.trim().toLowerCase();
    for (final e in JobExperience.values) {
      if (e.name.toLowerCase() == v || e.canonical.toLowerCase() == v) return e;
    }
    return null;
  }
}
