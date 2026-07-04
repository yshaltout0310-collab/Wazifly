import '../../../features/recommendations/domain/recommendation_models.dart';

/// Persistence seam for the most recent [Recommendations] ("For You") result.
///
/// The Recommendations feature (Phase 4 · M3) caches its latest generation here
/// so re-entering the screen doesn't re-call the AI, and a refresh can compare
/// signatures to avoid unnecessary calls. Only the latest is kept (not a full
/// history) — mirroring the resume-analysis cache seam.
///
/// Today the only implementation is `InMemoryRecommendationsStore` (session
/// scoped). Adding durable persistence later — a local cache or a Firestore
/// `users/{uid}/recommendations/latest` document — means writing a new
/// [RecommendationsStore] and rebinding `recommendationsStoreProvider`. **No
/// feature code changes**, because everything depends on this interface.
abstract interface class RecommendationsStore {
  /// Re-emits the latest cached recommendations on every change (mirroring how
  /// Firestore `.snapshots()` re-emits); `null` until something is stored.
  Stream<Recommendations?> watchLatest();

  /// Synchronous peek at the cache (seeds the controller at construction).
  Recommendations? read();

  /// Persists [recommendations] as the latest result.
  Future<void> save(Recommendations recommendations);

  /// Clears the cached recommendations.
  Future<void> clear();
}
