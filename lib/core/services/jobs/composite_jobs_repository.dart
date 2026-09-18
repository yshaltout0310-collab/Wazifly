import '../../../shared/models/job.dart';
import 'job_query_filter.dart';
import 'jobs_repository.dart';

/// Serves the seeker catalogue from a **live** source, with a static catalogue
/// behind it.
///
/// Firestore is the source of truth for real postings: every job an employer
/// publishes appears here, newest first, ahead of everything else. The bundled
/// demo catalogue (`SeedJobsRepository`) is appended afterwards so the browse,
/// matching, recommendation and internship experiences are never empty — on a
/// fresh Firebase project, offline with a cold cache, or in a demo where no
/// employer has posted yet.
///
/// Why append rather than "fall back only when empty": the moment one employer
/// publishes a single job, an either/or fallback would collapse the seeker's
/// catalogue from the full demo set to that one posting, which reads as a
/// regression. Appending keeps real postings authoritative *and* the experience
/// populated.
///
/// Set [includeFallbackCatalogue] to `false` for a pure-production marketplace
/// in which only live Firestore postings are ever shown — that is the single
/// switch, and nothing else changes.
class CompositeJobsRepository implements JobsRepository {
  CompositeJobsRepository({
    required JobsRepository live,
    required JobsRepository fallback,
    this.includeFallbackCatalogue = true,
  })  : _live = live,
        _fallback = fallback;

  final JobsRepository _live;
  final JobsRepository _fallback;

  /// Whether the bundled demo catalogue is appended after the live postings.
  final bool includeFallbackCatalogue;

  @override
  Future<List<Job>> fetchJobs() async {
    final live = await _live.fetchJobs();
    if (!includeFallbackCatalogue) return live;

    final seen = {for (final j in live) j.id};
    final demo = await _fallback.fetchJobs();
    return [
      ...live,
      ...demo.where((j) => seen.add(j.id)),
    ];
  }

  @override
  Future<Job?> fetchJobById(String id) async {
    final live = await _live.fetchJobById(id);
    if (live != null) return live;
    if (!includeFallbackCatalogue) return null;
    return _fallback.fetchJobById(id);
  }

  /// Filtering runs over the merged catalogue so a query can never return only
  /// one source's matches.
  @override
  Future<List<Job>> searchJobs(JobQuery query) async =>
      applyJobQuery(await fetchJobs(), query);
}
