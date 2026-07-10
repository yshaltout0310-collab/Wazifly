import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/models/learning_profile.dart';
import '../firebase/firebase_service.dart';
import 'learning_profile_repository.dart';

/// Firestore-backed [LearningProfileRepository] — the production path.
///
/// The **only** file importing `cloud_firestore` for learning interests. Stores
/// one document per user at `users/{uid}/learning/interests`. Every method
/// degrades gracefully when Firebase isn't configured (reads emit an empty
/// profile, writes no-op) so calling code never branches on backend
/// availability — the `FirestoreCvRepository` discipline.
class FirestoreLearningProfileRepository implements LearningProfileRepository {
  FirestoreLearningProfileRepository([FirebaseFirestore? firestore])
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  bool get _ready => FirebaseService.instance.isReady;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid).collection('learning').doc('interests');

  @override
  Stream<LearningProfile> watchProfile(String uid) {
    if (!_ready || uid.isEmpty) {
      return Stream<LearningProfile>.value(LearningProfile.empty(uid));
    }
    return _doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return LearningProfile.empty(uid);
      return LearningProfile.fromJson({...data, 'uid': uid}, uid: uid);
    }).handleError((Object e) {
      debugPrint('[LearningProfile] watchProfile failed: $e');
    });
  }

  @override
  Future<LearningProfile> fetchProfile(String uid) async {
    if (!_ready || uid.isEmpty) return LearningProfile.empty(uid);
    try {
      final snap = await _doc(uid).get();
      final data = snap.data();
      if (data == null) return LearningProfile.empty(uid);
      return LearningProfile.fromJson({...data, 'uid': uid}, uid: uid);
    } catch (e) {
      debugPrint('[LearningProfile] fetchProfile failed: $e');
      return LearningProfile.empty(uid);
    }
  }

  @override
  Future<void> saveProfile(LearningProfile profile) async {
    if (!_ready || profile.uid.isEmpty) return;
    final data = profile.toJson()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    try {
      // Firestore's offline persistence durably queues the write and updates
      // the local cache (so the reactive stream re-emits) immediately, but the
      // returned Future only completes on server ack — which never arrives while
      // offline. Bound the wait: a timeout means the write is safely queued and
      // will sync on reconnect, so we treat it as an optimistic success rather
      // than hanging the UI. A real (online) rule/permission failure still
      // rethrows so the controller can surface it.
      await _doc(profile.uid)
          .set(data, SetOptions(merge: true))
          .timeout(const Duration(seconds: 2));
    } on TimeoutException {
      debugPrint('[LearningProfile] saveProfile queued offline (will sync)');
    } catch (e) {
      debugPrint('[LearningProfile] saveProfile failed: $e');
      rethrow; // let the optimistic controller roll back
    }
  }
}
