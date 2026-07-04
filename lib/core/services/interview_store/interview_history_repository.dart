import '../../../features/interview_prep/domain/interview_models.dart';

/// Owns the user's past interview sessions.
///
/// An interface so the in-memory store today can be swapped for a Firestore
/// (`users/{uid}/interviews`) implementation later by rebinding
/// `interviewHistoryRepositoryProvider` — **no feature code changes**. The
/// [watchSessions] stream maps 1:1 to a Firestore `.snapshots()` query, exactly
/// like `ApplicationsRepository`.
abstract interface class InterviewHistoryRepository {
  /// Emits the current sessions (newest first) and re-emits on every change.
  Stream<List<InterviewSession>> watchSessions();

  /// Inserts or replaces [session] by its id.
  Future<void> saveSession(InterviewSession session);

  /// Returns the session with [id], or null.
  Future<InterviewSession?> findById(String id);

  /// Removes the session [id].
  Future<void> delete(String id);
}
