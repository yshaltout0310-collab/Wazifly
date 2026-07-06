import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_providers.dart';
import '../../../shared/models/job_posting.dart';
import 'firestore_employer_jobs_repository.dart';

/// Owns an employer's job postings at `jobs/{jobId}` (write path).
///
/// A **separate** interface from the read-only seeker [JobsRepository]
/// (different responsibility: owner-scoped CRUD vs. public browse). Deliberately
/// thin persistence — status transitions, soft-delete, and duplication are pure
/// [JobPosting] methods computed by the controllers, then persisted via
/// [createJob]/[updateJob]. Swap the binding (Firestore ↔ in-memory) with **no
/// feature changes** — the same seam as `CompanyRepository`.
abstract interface class EmployerJobsRepository {
  /// Emits the company's postings (soft-deleted excluded), newest-updated first,
  /// and re-emits on every change — maps 1:1 to a Firestore `.snapshots()` query.
  Stream<List<JobPosting>> watchJobs(String companyId);

  /// One-shot read of a posting by id (includes soft-deleted, for audit).
  Future<JobPosting?> fetchJob(String id);

  /// Persists a new posting at `posting.id` (the caller assigns a stable id).
  Future<JobPosting> createJob(JobPosting posting);

  /// Merges an updated posting (status change / soft delete / edit).
  Future<void> updateJob(JobPosting posting);
}

/// The app-wide employer-jobs repository. Firestore in production; overridden
/// with an in-memory fake in tests. Swap this one binding to change the backend.
final employerJobsRepositoryProvider = Provider<EmployerJobsRepository>(
  (ref) => FirestoreEmployerJobsRepository(),
);

/// Reactive view of the signed-in employer's postings (companyId == uid in
/// Milestone 1). Tracks the authenticated uid and pipes the repository stream.
final employerJobsProvider = StreamProvider<List<JobPosting>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<List<JobPosting>>.value(const []);
  return ref.watch(employerJobsRepositoryProvider).watchJobs(user.uid);
});
