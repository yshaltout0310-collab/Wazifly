import '../../../shared/models/application.dart';
import '../../../shared/models/job.dart';

/// Owns the user's job applications.
///
/// An interface so the in-memory store today can be swapped for a Firestore
/// (`users/{uid}/applications`) implementation later by rebinding
/// `applicationsRepositoryProvider` — **no feature code changes**. The
/// [watchApplications] stream maps 1:1 to a Firestore `.snapshots()` query.
abstract interface class ApplicationsRepository {
  /// Emits the current applications list and re-emits on every change.
  Stream<List<Application>> watchApplications();

  /// Creates a Pending application for [job], optionally recording the [cvId] /
  /// [cvName] the seeker submitted. Idempotent per `job.id`: if one already
  /// exists it is returned unchanged.
  Future<Application> apply({
    required Job job,
    String cvId = '',
    String cvName = '',
  });

  /// Advances the application [id] to [status], appending a history event.
  Future<void> updateStatus(String id, ApplicationStatus status);

  /// Removes the application [id].
  Future<void> withdraw(String id);

  /// Returns the application for [jobId], or null if the user hasn't applied.
  Future<Application?> findByJobId(String jobId);
}
