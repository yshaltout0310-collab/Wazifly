import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cloud_storage/cloud_storage_service.dart';

/// Uploads a user's profile photo and returns its public download URL.
///
/// A thin, testable seam over storage: the Firebase implementation delegates to
/// [CloudStorageService], and tests bind an in-memory fake. Swap the binding to
/// change where photos live — **no feature changes**.
abstract interface class ProfileImageStorage {
  /// Uploads [bytes] as the user's profile photo; returns the download URL, or
  /// null when storage is unconfigured / the upload fails.
  Future<String?> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  });
}

/// Production storage: writes to `users/{uid}/profile.jpg` via Firebase Storage.
class FirebaseProfileImageStorage implements ProfileImageStorage {
  FirebaseProfileImageStorage(this._storage);

  final CloudStorageService _storage;

  @override
  Future<String?> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) {
    return _storage.uploadBytes(
      path: _storage.profilePhotoPath(uid),
      bytes: bytes,
      contentType: contentType,
    );
  }
}

/// The app-wide profile-image storage (swap this binding for tests/alternate
/// backends).
final profileImageStorageProvider = Provider<ProfileImageStorage>(
  (ref) => FirebaseProfileImageStorage(ref.watch(cloudStorageServiceProvider)),
);
