/// Employment type of a job posting.
///
/// [canonical] is the human string stored on the projected public `Job`
/// (matching the seed dataset's values like "Full-time"/"Contract"), so a
/// `JobPosting.toJob()` projection is seed-compatible for the seeker platform.
enum EmploymentType {
  fullTime,
  partTime,
  contract,
  internship,
  temporary;

  String get canonical => switch (this) {
        EmploymentType.fullTime => 'Full-time',
        EmploymentType.partTime => 'Part-time',
        EmploymentType.contract => 'Contract',
        EmploymentType.internship => 'Internship',
        EmploymentType.temporary => 'Temporary',
      };

  /// Tolerant parse: accepts the enum name ("fullTime") or the canonical string
  /// ("Full-time"); returns null for missing/unknown (the field is optional).
  static EmploymentType? fromName(Object? value) {
    if (value is! String) return null;
    final v = value.trim().toLowerCase();
    for (final t in EmploymentType.values) {
      if (t.name.toLowerCase() == v || t.canonical.toLowerCase() == v) return t;
    }
    return null;
  }
}
