import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/recommendations/domain/recommendation_models.dart';
import 'recommendations_store.dart';

/// Session-scoped [RecommendationsStore]: keeps the latest result in memory and
/// re-emits it through a broadcast stream (mirroring Firestore `.snapshots()`).
/// Swap the binding for a `FirestoreRecommendationsStore` later with no feature
/// changes.
class InMemoryRecommendationsStore implements RecommendationsStore {
  InMemoryRecommendationsStore({Recommendations? seed}) : _cached = seed;

  Recommendations? _cached;
  final _controller = StreamController<Recommendations?>.broadcast();

  @override
  Stream<Recommendations?> watchLatest() async* {
    yield _cached; // current value to new listeners
    yield* _controller.stream;
  }

  @override
  Recommendations? read() => _cached;

  @override
  Future<void> save(Recommendations recommendations) async {
    _cached = recommendations;
    _controller.add(_cached);
  }

  @override
  Future<void> clear() async {
    _cached = null;
    _controller.add(null);
  }
}

/// The app-wide recommendations cache (swap this binding for a Firestore
/// `users/{uid}/recommendations/latest` doc later — no feature changes).
final recommendationsStoreProvider = Provider<RecommendationsStore>(
  (ref) => InMemoryRecommendationsStore(),
);

/// Reactive view of the latest cached recommendations (maps to a Firestore
/// snapshot stream). `null` until the first generation.
final latestRecommendationsProvider = StreamProvider<Recommendations?>(
  (ref) => ref.watch(recommendationsStoreProvider).watchLatest(),
);
