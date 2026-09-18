import '../../../shared/models/job.dart';
import 'jobs_repository.dart';

/// Applies a [JobQuery] to an in-memory list of [Job]s.
///
/// Extracted from `SeedJobsRepository` so the Firestore-backed source applies
/// **exactly the same** text/filter/pagination semantics as the bundled
/// catalogue — one implementation, so the two sources can never drift.
///
/// The filtering deliberately runs in Dart rather than as Firestore `where`
/// clauses: free-text matching across title/company/location/skills is not
/// expressible as a Firestore query, and combining several equality filters with
/// an `orderBy` would force a composite index per filter combination. The
/// catalogue is small and already bounded by a read limit, so filtering the
/// fetched page client-side is both correct and cheaper. See
/// `FirestoreJobsRepository`.
List<Job> applyJobQuery(List<Job> source, JobQuery query) {
  final text = query.text.trim().toLowerCase();
  final loc = query.location?.trim().toLowerCase();

  var jobs = source.where((j) {
    if (query.remoteOnly && !j.remote) return false;
    if (query.employmentTypes.isNotEmpty &&
        !query.employmentTypes.contains(j.employmentType)) {
      return false;
    }
    if (query.seniorities.isNotEmpty &&
        !query.seniorities.contains(j.seniority)) {
      return false;
    }
    // Country/location filter keeps jobs in that place PLUS remote jobs
    // (remote roles are open regardless of the seeker's country).
    if (loc != null &&
        loc.isNotEmpty &&
        !j.remote &&
        !j.location.toLowerCase().contains(loc)) {
      return false;
    }
    if (text.isNotEmpty && !jobMatchesText(j, text)) return false;
    return true;
  }).toList(growable: false);

  // Pagination (optional).
  if (query.offset > 0) {
    jobs = jobs.length > query.offset ? jobs.sublist(query.offset) : const [];
  }
  final limit = query.limit;
  if (limit != null && jobs.length > limit) {
    jobs = jobs.sublist(0, limit);
  }
  return jobs;
}

/// Free-text match across the fields a seeker would reasonably search by.
/// [text] must already be lower-cased and trimmed.
bool jobMatchesText(Job j, String text) {
  if (j.title.toLowerCase().contains(text)) return true;
  if (j.company.toLowerCase().contains(text)) return true;
  if (j.location.toLowerCase().contains(text)) return true;
  for (final s in j.requiredSkills) {
    if (s.toLowerCase().contains(text)) return true;
  }
  return false;
}
