import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/models/application_note.dart';
import '../firebase/firebase_service.dart';
import 'employer_notes_repository.dart';

/// Firestore-backed [EmployerNotesRepository] — the production path.
///
/// Queries by `ownerUid` **and** `applicationId` (two equality filters — no
/// composite index needed) so results are provably owner-owned (the rule
/// authorizes reads only when `ownerUid == auth.uid`). Sort runs in Dart. Writes
/// rethrow. Degrades to empty/no-op when Firebase isn't ready.
class FirestoreEmployerNotesRepository implements EmployerNotesRepository {
  FirestoreEmployerNotesRepository([FirebaseFirestore? firestore])
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  static const String _collection = 'applicationNotes';

  bool get _ready => FirebaseService.instance.isReady;

  CollectionReference<Map<String, dynamic>> get _notes =>
      (_firestore ?? FirebaseFirestore.instance).collection(_collection);

  @override
  Stream<List<ApplicationNote>> watchNotes(
      String applicationId, String ownerUid) {
    if (!_ready) return Stream<List<ApplicationNote>>.value(const []);
    return _notes
        .where('ownerUid', isEqualTo: ownerUid)
        .where('applicationId', isEqualTo: applicationId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ApplicationNote.fromJson({...d.data(), 'id': d.id}))
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    }).handleError((Object e) {
      debugPrint('[EmployerNotes] watch failed: $e');
    });
  }

  @override
  Future<ApplicationNote> addNote(ApplicationNote note) async {
    if (!_ready) return note;
    final data = note.toJson()..remove('id');
    await _notes.doc(note.id).set(data);
    return note;
  }

  @override
  Future<void> updateNote(ApplicationNote note) async {
    if (!_ready) return;
    final data = note.toJson()..remove('id');
    await _notes.doc(note.id).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteNote(String id) async {
    if (!_ready) return;
    await _notes.doc(id).delete();
  }
}
