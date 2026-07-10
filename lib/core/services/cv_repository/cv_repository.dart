import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_providers.dart';
import 'cv_document.dart';
import 'firestore_cv_repository.dart';

/// Owns the user's CV repository at `resumes/{resumeId}` (owner-scoped).
///
/// A core service (like `UserProfileRepository`/`EmployerJobsRepository`) so the
/// CV Builder and the CV-library feature depend on **core**, never on each other.
/// Lifecycle transitions are pure [CvDocument] methods computed by the
/// controllers, then persisted via [createCv]/[updateCv]. Swap the binding
/// (Firestore ↔ in-memory) with **no feature changes**.
abstract interface class CvRepository {
  /// Emits the owner's CVs (soft-deleted excluded), newest-updated first, and
  /// re-emits on every change — maps 1:1 to a Firestore `.snapshots()` query.
  Stream<List<CvDocument>> watchCvs(String ownerUid);

  /// One-shot read of a CV by id (includes soft-deleted, for restore/audit).
  Future<CvDocument?> fetchCv(String id);

  /// Persists a new CV at `doc.id` (the caller assigns a stable id).
  Future<CvDocument> createCv(CvDocument doc);

  /// Merges an updated CV (rename / archive / restore / content / AI / soft delete).
  Future<void> updateCv(CvDocument doc);

  /// Atomically makes [id] the only default among the owner's CVs.
  Future<void> setDefault(String ownerUid, String id);
}

/// The app-wide CV repository. Firestore in production; overridden with an
/// in-memory fake in tests. Swap this one binding to change the backend.
final cvRepositoryProvider =
    Provider<CvRepository>((ref) => FirestoreCvRepository());

/// Reactive view of the signed-in user's CVs (soft-deleted excluded).
final cvDocumentsProvider = StreamProvider<List<CvDocument>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<List<CvDocument>>.value(const []);
  return ref.watch(cvRepositoryProvider).watchCvs(user.uid);
});

/// The active (non-archived) CVs.
final activeCvsProvider = Provider<List<CvDocument>>((ref) {
  final all = ref.watch(cvDocumentsProvider).valueOrNull ?? const [];
  return all.where((c) => c.isActive).toList(growable: false);
});

/// The user's default CV: the explicit default, else the most-recent active one,
/// else null when there are no active CVs.
final defaultCvProvider = Provider<CvDocument?>((ref) {
  final active = ref.watch(activeCvsProvider);
  if (active.isEmpty) return null;
  for (final c in active) {
    if (c.isDefault) return c;
  }
  return active.first; // active is already newest-updated first
});

/// Looks up one CV (active or archived) by id from the reactive stream, so the
/// detail screen re-renders as the CV changes. Null while loading / not found.
final cvByIdProvider = Provider.family<CvDocument?, String>((ref, id) {
  final all = ref.watch(cvDocumentsProvider).valueOrNull ?? const [];
  for (final c in all) {
    if (c.id == id) return c;
  }
  return null;
});
