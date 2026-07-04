import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../features/user_type/domain/user_type.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_profile.dart';
import '../firebase/firebase_service.dart';
import 'user_profile_repository.dart';

/// Firestore-backed [UserProfileRepository] — the production path.
///
/// Every method degrades gracefully when Firebase isn't configured (reads emit
/// null, writes no-op), so calling code never branches on backend availability.
class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository([FirebaseFirestore? firestore])
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  static const String _collection = 'users';

  bool get _ready => FirebaseService.instance.isReady;

  CollectionReference<Map<String, dynamic>> get _users =>
      (_firestore ?? FirebaseFirestore.instance).collection(_collection);

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    if (!_ready) return Stream<UserProfile?>.value(null);
    return _users.doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return UserProfile.fromJson({...data, 'uid': uid});
    }).handleError((Object e) {
      debugPrint('[UserProfileRepository] watchProfile failed: $e');
    });
  }

  @override
  Future<UserProfile?> fetchProfile(String uid) async {
    if (!_ready) return null;
    try {
      final snap = await _users.doc(uid).get();
      final data = snap.data();
      if (data == null) return null;
      return UserProfile.fromJson({...data, 'uid': uid});
    } catch (e) {
      debugPrint('[UserProfileRepository] fetchProfile failed: $e');
      return null;
    }
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    if (!_ready) return;
    try {
      final data = profile.toJson()
        ..remove('uid')
        ..['updatedAt'] = FieldValue.serverTimestamp();
      await _users.doc(profile.uid).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[UserProfileRepository] saveProfile failed: $e');
    }
  }

  @override
  Future<void> ensureProfile(AppUser user) async {
    if (!_ready) return;
    try {
      final doc = _users.doc(user.uid);
      final snapshot = await doc.get();
      final data = <String, dynamic>{
        'uid': user.uid,
        'authMethod': user.method.name,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'displayName': user.displayName,
        'photoUrl': user.photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!snapshot.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      await doc.set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[UserProfileRepository] ensureProfile failed: $e');
    }
  }

  @override
  Future<void> setUserType(String uid, UserType type) async {
    if (!_ready) return;
    try {
      await _users.doc(uid).set(
        {'userType': type.name, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[UserProfileRepository] setUserType failed: $e');
    }
  }

  @override
  Future<void> setPhotoUrl(String uid, String url) async {
    if (!_ready) return;
    try {
      await _users.doc(uid).set(
        {'photoUrl': url, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[UserProfileRepository] setPhotoUrl failed: $e');
    }
  }
}
