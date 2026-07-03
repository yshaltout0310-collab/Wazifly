import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persistence seam for the user's **saved** (bookmarked) job ids.
///
/// ("Applied" state is no longer here — it's derived from the applications
/// repository, which is the single source of truth.)
///
/// Today the only implementation is [InMemorySavedJobsStore] (session scoped).
/// Adding durable persistence later — a `SharedPreferences` set or a Firestore
/// `users/{uid}/savedJobs` collection — means writing a new [SavedJobsStore]
/// and rebinding [savedJobsStoreProvider]. **No feature code changes.**
abstract interface class SavedJobsStore {
  Set<String> read();
  Future<void> write(Set<String> ids);
}

/// Default store: keeps saved ids in memory for the app session only.
class InMemorySavedJobsStore implements SavedJobsStore {
  Set<String> _ids = const {};

  @override
  Set<String> read() => _ids;

  @override
  Future<void> write(Set<String> ids) async => _ids = Set.unmodifiable(ids);
}

/// The app-wide [SavedJobsStore]. Swap persistence by changing only this
/// binding (overridden with a fake/seed in tests).
final savedJobsStoreProvider =
    Provider<SavedJobsStore>((ref) => InMemorySavedJobsStore());

/// Reactive set of saved job ids, mirrored into the store on every change so
/// bookmarks survive navigation (and any future durable backend is written to
/// transparently).
class SavedJobsController extends StateNotifier<Set<String>> {
  SavedJobsController(this._store) : super(_store.read());

  final SavedJobsStore _store;

  Future<void> toggle(String id) async {
    final next = {...state};
    next.contains(id) ? next.remove(id) : next.add(id);
    state = next;
    await _store.write(next);
  }

  bool isSaved(String id) => state.contains(id);
}

final savedJobsProvider =
    StateNotifierProvider<SavedJobsController, Set<String>>(
  (ref) => SavedJobsController(ref.watch(savedJobsStoreProvider)),
);
