import 'dart:async';

import 'cv_document.dart';
import 'cv_repository.dart';

/// Session-scoped [CvRepository] for tests (and any Noop fallback). Pushes the
/// full list on every change through a broadcast stream, mirroring how Firestore
/// `.snapshots()` re-emits. Soft-deleted docs are excluded from the stream.
class InMemoryCvRepository implements CvRepository {
  InMemoryCvRepository({List<CvDocument> seed = const []}) {
    _items.addAll(seed);
  }

  final List<CvDocument> _items = [];
  final _controller = StreamController<List<CvDocument>>.broadcast();

  List<CvDocument> _visible() {
    final v = _items.where((c) => !c.isDeleted).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(v);
  }

  void _emit() => _controller.add(_visible());

  @override
  Stream<List<CvDocument>> watchCvs(String ownerUid) async* {
    yield _visible().where((c) => c.ownerUid == ownerUid).toList();
    yield* _controller.stream
        .map((l) => l.where((c) => c.ownerUid == ownerUid).toList());
  }

  @override
  Future<CvDocument?> fetchCv(String id) async {
    final i = _items.indexWhere((c) => c.id == id);
    return i == -1 ? null : _items[i];
  }

  @override
  Future<CvDocument> createCv(CvDocument doc) async {
    _items.insert(0, doc);
    _emit();
    return doc;
  }

  @override
  Future<void> updateCv(CvDocument doc) async {
    final i = _items.indexWhere((c) => c.id == doc.id);
    if (i == -1) {
      _items.insert(0, doc);
    } else {
      _items[i] = doc;
    }
    _emit();
  }

  @override
  Future<void> setDefault(String ownerUid, String id) async {
    var changed = false;
    for (var i = 0; i < _items.length; i++) {
      final c = _items[i];
      if (c.ownerUid != ownerUid) continue;
      final shouldBeDefault = c.id == id;
      if (c.isDefault != shouldBeDefault) {
        _items[i] = shouldBeDefault
            ? c.asDefault(c.updatedAt)
            : c.clearedDefault(c.updatedAt);
        changed = true;
      }
    }
    if (changed) _emit();
  }
}
