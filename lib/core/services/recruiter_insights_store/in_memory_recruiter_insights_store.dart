import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/employer/domain/analytics/recruiter_insights.dart';
import 'recruiter_insights_store.dart';

/// Session-scoped [RecruiterInsightsStore]: keeps the latest result in memory and
/// re-emits it through a broadcast stream (mirroring Firestore `.snapshots()`).
/// Swap the binding for a `FirestoreRecruiterInsightsStore` later with no feature
/// changes.
class InMemoryRecruiterInsightsStore implements RecruiterInsightsStore {
  InMemoryRecruiterInsightsStore({RecruiterInsights? seed}) : _cached = seed;

  RecruiterInsights? _cached;
  final _controller = StreamController<RecruiterInsights?>.broadcast();

  @override
  Stream<RecruiterInsights?> watchLatest() async* {
    yield _cached; // current value to new listeners
    yield* _controller.stream;
  }

  @override
  RecruiterInsights? read() => _cached;

  @override
  Future<void> save(RecruiterInsights insights) async {
    _cached = insights;
    _controller.add(_cached);
  }

  @override
  Future<void> clear() async {
    _cached = null;
    _controller.add(null);
  }
}

/// The app-wide recruiter-insights cache (swap this binding for a Firestore
/// `companies/{companyId}/insights/latest` doc later — no feature changes).
final recruiterInsightsStoreProvider = Provider<RecruiterInsightsStore>(
  (ref) => InMemoryRecruiterInsightsStore(),
);

/// Reactive view of the latest cached insights (maps to a Firestore snapshot
/// stream). `null` until the first generation.
final latestRecruiterInsightsProvider =
    StreamProvider<RecruiterInsights?>(
  (ref) => ref.watch(recruiterInsightsStoreProvider).watchLatest(),
);
