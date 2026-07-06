import 'dart:async';

import '../../../shared/models/employer_activity.dart';
import 'employer_activity_repository.dart';

/// Session-scoped [EmployerActivityRepository] for tests and offline runs.
class InMemoryEmployerActivityRepository implements EmployerActivityRepository {
  InMemoryEmployerActivityRepository({List<EmployerActivity> seed = const []}) {
    for (final a in seed) {
      _items[a.id] = a;
    }
  }

  final Map<String, EmployerActivity> _items = {};
  final Map<String, StreamController<List<EmployerActivity>>> _controllers = {};

  StreamController<List<EmployerActivity>> _controllerFor(String ownerUid) =>
      _controllers.putIfAbsent(
        ownerUid,
        () => StreamController<List<EmployerActivity>>.broadcast(),
      );

  List<EmployerActivity> _snapshot(String ownerUid) {
    final list =
        _items.values.where((a) => a.ownerUid == ownerUid).toList();
    list.sort((a, b) => b.at.compareTo(a.at));
    return List.unmodifiable(list);
  }

  /// Recorded activities, for test assertions.
  List<EmployerActivity> get logged => List.unmodifiable(_items.values);

  @override
  Future<void> log(EmployerActivity activity) async {
    _items[activity.id] = activity;
    _controllerFor(activity.ownerUid).add(_snapshot(activity.ownerUid));
  }

  @override
  Stream<List<EmployerActivity>> watchActivity(String ownerUid) async* {
    yield _snapshot(ownerUid);
    yield* _controllerFor(ownerUid).stream;
  }
}
