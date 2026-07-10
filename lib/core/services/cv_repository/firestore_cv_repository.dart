import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firebase_service.dart';
import 'cv_document.dart';
import 'cv_repository.dart';

/// Firestore-backed [CvRepository] — the production path.
///
/// The **only** file importing `cloud_firestore` for CVs. Every method degrades
/// gracefully when Firebase isn't configured (reads emit empty/null, writes
/// no-op), so calling code never branches on backend availability. Soft-deleted
/// docs are dropped and the list is sorted **client-side** to avoid a composite
/// index (the P6·M2 discipline).
class FirestoreCvRepository implements CvRepository {
  FirestoreCvRepository([FirebaseFirestore? firestore]) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  static const String _collection = 'resumes';

  bool get _ready => FirebaseService.instance.isReady;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection(_collection);

  @override
  Stream<List<CvDocument>> watchCvs(String ownerUid) {
    if (!_ready) return Stream<List<CvDocument>>.value(const []);
    return _col
        .where('ownerUid', isEqualTo: ownerUid)
        .limit(300)
        .snapshots()
        .map((snap) {
      final docs = snap.docs
          .map((d) => CvDocument.fromJson({...d.data(), 'id': d.id}))
          .where((c) => !c.isDeleted)
          .toList();
      docs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return docs;
    }).handleError((Object e) {
      debugPrint('[CvRepository] watchCvs failed: $e');
    });
  }

  @override
  Future<CvDocument?> fetchCv(String id) async {
    if (!_ready) return null;
    try {
      final snap = await _col.doc(id).get();
      final data = snap.data();
      if (data == null) return null;
      return CvDocument.fromJson({...data, 'id': id});
    } catch (e) {
      debugPrint('[CvRepository] fetchCv failed: $e');
      return null;
    }
  }

  @override
  Future<CvDocument> createCv(CvDocument doc) async {
    if (!_ready) return doc;
    try {
      final data = doc.toJson()
        ..remove('id')
        ..['createdAt'] = FieldValue.serverTimestamp()
        ..['updatedAt'] = FieldValue.serverTimestamp();
      await _col.doc(doc.id).set(data);
    } catch (e) {
      debugPrint('[CvRepository] createCv failed: $e');
    }
    return doc;
  }

  @override
  Future<void> updateCv(CvDocument doc) async {
    if (!_ready) return;
    try {
      final data = doc.toJson()
        ..remove('id')
        ..remove('createdAt')
        ..['updatedAt'] = FieldValue.serverTimestamp();
      await _col.doc(doc.id).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[CvRepository] updateCv failed: $e');
    }
  }

  @override
  Future<void> setDefault(String ownerUid, String id) async {
    if (!_ready) return;
    try {
      final snap = await _col.where('ownerUid', isEqualTo: ownerUid).get();
      final batch = _db.batch();
      for (final d in snap.docs) {
        final shouldBeDefault = d.id == id;
        if ((d.data()['isDefault'] == true) != shouldBeDefault) {
          batch.set(
            d.reference,
            {
              'isDefault': shouldBeDefault,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[CvRepository] setDefault failed: $e');
    }
  }
}
