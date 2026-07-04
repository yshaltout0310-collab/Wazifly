/// Industry sector a company operates in.
///
/// A small, stable enum (like `ExperienceLevel`) so it round-trips cleanly to
/// Firestore, localizes to EN/AR, and can be reused by future employer search /
/// job-matching. Optional on the company (returns null for missing/unknown).
enum Industry {
  technology,
  finance,
  healthcare,
  education,
  retail,
  manufacturing,
  construction,
  hospitality,
  media,
  energy,
  transportation,
  government,
  nonprofit,
  other;

  /// Parses a stored name back to a value, tolerating case/whitespace and
  /// returning null for missing/unknown values (the field is optional).
  static Industry? fromName(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim().toLowerCase();
    for (final industry in Industry.values) {
      if (industry.name == normalized) return industry;
    }
    return null;
  }
}
