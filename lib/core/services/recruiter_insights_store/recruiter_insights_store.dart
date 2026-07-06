import '../../../features/employer/domain/analytics/recruiter_insights.dart';

/// Persistence seam for the most recent [RecruiterInsights] result.
///
/// The Employer Analytics feature (Phase 5 · M4) caches its latest AI insights
/// here so re-entering the screen doesn't re-call the model, and a refresh can
/// compare signatures to avoid unnecessary calls. Only the latest is kept (not a
/// full history) — mirroring the recommendations cache seam.
///
/// Today the only implementation is `InMemoryRecruiterInsightsStore` (session
/// scoped). Adding durable persistence later — a Firestore
/// `companies/{companyId}/insights/latest` document — means writing a new
/// [RecruiterInsightsStore] and rebinding `recruiterInsightsStoreProvider`. **No
/// feature code changes**, because everything depends on this interface. (A
/// Firestore-backed version would need an owner-scoped rule on that subcollection;
/// none is added this milestone since the store is in-memory.)
abstract interface class RecruiterInsightsStore {
  /// Re-emits the latest cached insights on every change (mirroring how
  /// Firestore `.snapshots()` re-emits); `null` until something is stored.
  Stream<RecruiterInsights?> watchLatest();

  /// Synchronous peek at the cache (seeds the controller at construction).
  RecruiterInsights? read();

  /// Persists [insights] as the latest result.
  Future<void> save(RecruiterInsights insights);

  /// Clears the cached insights.
  Future<void> clear();
}
