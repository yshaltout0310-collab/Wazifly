import 'dart:async';

import '../../../shared/models/application_note.dart';
import 'employer_notes_repository.dart';

/// Session-scoped [EmployerNotesRepository] for tests and offline runs.
class InMemoryEmployerNotesRepository implements EmployerNotesRepository {
  InMemoryEmployerNotesRepository({List<ApplicationNote> seed = const []}) {
    for (final n in seed) {
      _items[n.id] = n;
    }
  }

  final Map<String, ApplicationNote> _items = {};
  final Map<String, StreamController<List<ApplicationNote>>> _controllers = {};

  String _key(String applicationId, String ownerUid) => '$ownerUid::$applicationId';

  StreamController<List<ApplicationNote>> _controllerFor(
          String applicationId, String ownerUid) =>
      _controllers.putIfAbsent(
        _key(applicationId, ownerUid),
        () => StreamController<List<ApplicationNote>>.broadcast(),
      );

  List<ApplicationNote> _snapshot(String applicationId, String ownerUid) {
    final list = _items.values
        .where((n) => n.applicationId == applicationId && n.ownerUid == ownerUid)
        .toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(list);
  }

  void _emit(String applicationId, String ownerUid) => _controllerFor(
        applicationId,
        ownerUid,
      ).add(_snapshot(applicationId, ownerUid));

  @override
  Stream<List<ApplicationNote>> watchNotes(
      String applicationId, String ownerUid) async* {
    yield _snapshot(applicationId, ownerUid);
    yield* _controllerFor(applicationId, ownerUid).stream;
  }

  @override
  Future<ApplicationNote> addNote(ApplicationNote note) async {
    _items[note.id] = note;
    _emit(note.applicationId, note.ownerUid);
    return note;
  }

  @override
  Future<void> updateNote(ApplicationNote note) async {
    _items[note.id] = note;
    _emit(note.applicationId, note.ownerUid);
  }

  @override
  Future<void> deleteNote(String id) async {
    final note = _items.remove(id);
    if (note != null) _emit(note.applicationId, note.ownerUid);
  }
}
