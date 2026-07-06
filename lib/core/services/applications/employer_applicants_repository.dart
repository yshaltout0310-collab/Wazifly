import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_providers.dart';
import '../../../shared/models/application.dart';
import 'firestore_employer_applicants_repository.dart';

/// Read/manage path for an **employer's** applicants at `applications/{id}`,
/// filtered by `ownerUid` (the job owner).
///
/// A **separate** interface from the seeker-side [ApplicationsRepository] — the
/// same split as `EmployerJobsRepository` vs the read-only seeker `JobsRepository`:
/// both talk to the same collection + shared [Application] model, but the seeker
/// reads its own docs by `applicantUid` while the employer reads/updates by
/// `ownerUid`. Swap the binding (Firestore ↔ in-memory) with **no feature
/// changes**.
abstract interface class EmployerApplicantsRepository {
  /// Emits the employer's applications (newest-updated first), re-emitting on
  /// every change — maps 1:1 to a Firestore `.snapshots()` query on `ownerUid`.
  Stream<List<Application>> watchApplicants(String ownerUid);

  /// One-shot read of an application by id.
  Future<Application?> fetchApplicant(String id);

  /// Persists an updated application (e.g. an appended status change). **Rethrows
  /// on failure** so the optimistic controller can roll back.
  Future<void> updateApplication(Application application);
}

/// The app-wide employer-applicants repository. Firestore in production; overridden
/// with an in-memory fake in tests. Swap this one binding to change the backend.
final employerApplicantsRepositoryProvider =
    Provider<EmployerApplicantsRepository>(
  (ref) => FirestoreEmployerApplicantsRepository(),
);

/// Reactive view of the signed-in employer's applicants. Tracks the authenticated
/// uid and pipes the repository stream (mirrors `employerJobsProvider`).
final employerApplicantsProvider = StreamProvider<List<Application>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<List<Application>>.value(const []);
  return ref.watch(employerApplicantsRepositoryProvider).watchApplicants(user.uid);
});
