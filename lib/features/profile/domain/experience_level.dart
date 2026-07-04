/// Career seniority band a job seeker can declare on their profile.
///
/// Kept as a small, stable enum (not free-form "years") so it round-trips
/// cleanly to Firestore, localizes to EN/AR, and can be reused by AI features
/// (Job Matching, recommendations) and a future Employer Dashboard filter.
enum ExperienceLevel {
  entry,
  junior,
  mid,
  senior,
  lead;

  /// Parses a stored name back to a level, tolerating case/whitespace and
  /// returning null for missing/unknown values (the field is optional).
  static ExperienceLevel? fromName(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim().toLowerCase();
    for (final level in ExperienceLevel.values) {
      if (level.name == normalized) return level;
    }
    return null;
  }
}
