import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firebase/firebase_service.dart';
import '../../../shared/models/app_user.dart';
import '../../user_type/domain/user_type.dart';

/// Reads/writes the `users/{uid}` profile document in Cloud Firestore.
///
/// Every method no-ops safely when Firebase isn't configured, so calling code
/// never needs to branch on backend availability.
class UserProfileRepository {
  UserProfileRepository([FirebaseFirestore? firestore])
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  static const String _collection = 'users';

  bool get _ready => FirebaseService.instance.isReady;

  CollectionReference<Map<String, dynamic>> get _users =>
      (_firestore ?? FirebaseFirestore.instance).collection(_collection);

  /// Creates the profile on first sign-in, or refreshes mutable fields on
  /// subsequent sign-ins. Safe to call after every successful auth.
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

  /// Persists the chosen role to the user's profile.
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
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => UserProfileRepository(),
);
