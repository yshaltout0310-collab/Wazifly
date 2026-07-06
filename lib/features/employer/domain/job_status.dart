/// Lifecycle status of an employer job posting.
///
/// A small, stable enum so it round-trips cleanly to Firestore and localizes to
/// EN/AR. [allowedNext] encodes the legal transitions the UI + controllers
/// enforce.
enum JobStatus {
  draft,
  published,
  archived,
  closed;

  static JobStatus fromName(Object? value) {
    if (value is! String) return JobStatus.draft;
    final v = value.trim().toLowerCase();
    for (final s in JobStatus.values) {
      if (s.name == v) return s;
    }
    return JobStatus.draft;
  }

  /// Statuses this one may transition to (owner actions).
  Set<JobStatus> get allowedNext => switch (this) {
        JobStatus.draft => const {JobStatus.published},
        JobStatus.published => const {JobStatus.archived, JobStatus.closed},
        JobStatus.archived => const {JobStatus.published, JobStatus.draft},
        JobStatus.closed => const {JobStatus.published},
      };

  bool canTransitionTo(JobStatus next) => allowedNext.contains(next);
}
