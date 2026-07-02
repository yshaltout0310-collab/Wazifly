import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persistence seam for the user's per-job interactions: **saved** (bookmarked)
/// and **applied** job ids.
///
/// Today the only implementation is [InMemoryJobInteractionsStore] (session
/// scoped). Adding durable persistence later — a `SharedPreferences` set or a
/// Firestore `users/{uid}/savedJobs` collection — means writing a new
/// [JobInteractionsStore] and rebinding [jobInteractionsStoreProvider]. **No
/// feature code changes.** Mirrors the resume/chat store seams.
abstract interface class JobInteractionsStore {
  Set<String> readSaved();
  Future<void> setSaved(Set<String> ids);

  Set<String> readApplied();
  Future<void> setApplied(Set<String> ids);
}

/// Default store: keeps interactions in memory for the app session only.
class InMemoryJobInteractionsStore implements JobInteractionsStore {
  Set<String> _saved = const {};
  Set<String> _applied = const {};

  @override
  Set<String> readSaved() => _saved;

  @override
  Future<void> setSaved(Set<String> ids) async =>
      _saved = Set.unmodifiable(ids);

  @override
  Set<String> readApplied() => _applied;

  @override
  Future<void> setApplied(Set<String> ids) async =>
      _applied = Set.unmodifiable(ids);
}

/// The app-wide [JobInteractionsStore]. Swap persistence strategies by changing
/// only this binding (overridden with a fake/seed in tests).
final jobInteractionsStoreProvider =
    Provider<JobInteractionsStore>((ref) => InMemoryJobInteractionsStore());

/// Reactive saved + applied job-id sets, mirrored into the store on every
/// change so bookmarks/applications survive navigation (and any future durable
/// backend is written to transparently).
class JobInteractionsController extends StateNotifier<JobInteractions> {
  JobInteractionsController(this._store)
      : super(JobInteractions(
          saved: _store.readSaved(),
          applied: _store.readApplied(),
        ));

  final JobInteractionsStore _store;

  Future<void> toggleSaved(String id) async {
    final next = {...state.saved};
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(saved: next);
    await _store.setSaved(next);
  }

  Future<void> markApplied(String id) async {
    if (state.applied.contains(id)) return;
    final next = {...state.applied, id};
    state = state.copyWith(applied: next);
    await _store.setApplied(next);
  }

  bool isSaved(String id) => state.saved.contains(id);
  bool isApplied(String id) => state.applied.contains(id);
}

/// Immutable snapshot of the user's saved + applied job ids.
class JobInteractions {
  const JobInteractions({required this.saved, required this.applied});

  final Set<String> saved;
  final Set<String> applied;

  JobInteractions copyWith({Set<String>? saved, Set<String>? applied}) =>
      JobInteractions(
        saved: saved ?? this.saved,
        applied: applied ?? this.applied,
      );
}

final jobInteractionsProvider =
    StateNotifierProvider<JobInteractionsController, JobInteractions>(
  (ref) => JobInteractionsController(ref.watch(jobInteractionsStoreProvider)),
);
