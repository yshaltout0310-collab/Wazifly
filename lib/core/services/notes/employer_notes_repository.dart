import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_providers.dart';
import '../../../shared/models/application_note.dart';
import 'firestore_employer_notes_repository.dart';

/// Owner-private employer notes at `applicationNotes/{id}`.
///
/// A **separate** collection from `applications` (which the applicant can read),
/// so notes stay private to the employer. Every query filters on `ownerUid` to
/// match the security rule's owner clause exactly. Swap the binding
/// (Firestore ↔ in-memory) with **no feature changes**.
abstract interface class EmployerNotesRepository {
  /// Emits the notes for [applicationId] owned by [ownerUid], oldest-first,
  /// re-emitting on change.
  Stream<List<ApplicationNote>> watchNotes(String applicationId, String ownerUid);

  /// Persists a new note. **Rethrows on failure** (optimistic rollback).
  Future<ApplicationNote> addNote(ApplicationNote note);

  /// Updates a note's text. Rethrows on failure.
  Future<void> updateNote(ApplicationNote note);

  /// Deletes a note. Rethrows on failure.
  Future<void> deleteNote(String id);
}

/// The app-wide employer-notes repository. Firestore in production; overridden
/// with an in-memory fake in tests.
final employerNotesRepositoryProvider = Provider<EmployerNotesRepository>(
  (ref) => FirestoreEmployerNotesRepository(),
);

/// Reactive notes for a given application (auth-scoped to the signed-in owner).
final notesForApplicationProvider =
    StreamProvider.family<List<ApplicationNote>, String>((ref, applicationId) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<List<ApplicationNote>>.value(const []);
  return ref
      .watch(employerNotesRepositoryProvider)
      .watchNotes(applicationId, user.uid);
});
