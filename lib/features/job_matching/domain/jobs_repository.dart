import 'job.dart';

/// Source of job postings to match against.
///
/// An interface (not a concrete class) so the current bundled seed dataset
/// (`SeedJobsRepository`) can be swapped for a real jobs API later without
/// touching any matching/feature code — the only requirement is "give me a list
/// of [Job]s".
abstract interface class JobsRepository {
  /// Returns the available jobs. May be empty if the source has none.
  Future<List<Job>> fetchJobs();
}
