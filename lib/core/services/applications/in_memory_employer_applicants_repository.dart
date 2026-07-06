import 'dart:async';

import '../../../shared/models/application.dart';
import 'employer_applicants_repository.dart';

/// Session-scoped [EmployerApplicantsRepository] for tests and offline runs.
///
/// Holds applications in memory keyed by id, and re-emits an owner's live
/// (newest-first) list on every change through a per-owner broadcast stream
/// (mirroring Firestore `.snapshots()`).
class InMemoryEmployerApplicantsRepository
    implements EmployerApplicantsRepository {
  InMemoryEmployerApplicantsRepository({List<Application> seed = const []}) {
    for (final a in seed) {
      _items[a.id] = a;
    }
  }

  final Map<String, Application> _items = {};
  final Map<String, StreamController<List<Application>>> _controllers = {};

  StreamController<List<Application>> _controllerFor(String ownerUid) =>
      _controllers.putIfAbsent(
        ownerUid,
        () => StreamController<List<Application>>.broadcast(),
      );

  List<Application> _snapshot(String ownerUid) {
    final list =
        _items.values.where((a) => a.ownerUid == ownerUid).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(list);
  }

  void _emit(String ownerUid) =>
      _controllerFor(ownerUid).add(_snapshot(ownerUid));

  @override
  Stream<List<Application>> watchApplicants(String ownerUid) async* {
    yield _snapshot(ownerUid);
    yield* _controllerFor(ownerUid).stream;
  }

  @override
  Future<Application?> fetchApplicant(String id) async => _items[id];

  @override
  Future<void> updateApplication(Application application) async {
    _items[application.id] = application;
    _emit(application.ownerUid);
  }
}
