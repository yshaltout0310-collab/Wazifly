import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cloud_storage/firebase_storage_service.dart';
import '../cloud_storage/storage_paths.dart';
import '../cloud_storage/storage_service.dart';

/// Uploads / removes a user's profile photo — the profile-media repository.
///
/// A thin, testable seam over [StorageService]: the Firebase-backed
/// implementation delegates to it, and tests bind an in-memory fake. Swap the
/// binding to change where photos live — **no feature changes**.
abstract interface class ProfileImageStorage {
  /// Uploads [bytes] as the user's profile photo; returns the download URL, or
  /// null when storage is unconfigured / the upload fails. [onProgress] reports
  /// upload progress.
  Future<String?> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    void Function(StorageUploadProgress progress)? onProgress,
  });

  /// Removes the user's profile photo (no-op when absent / unconfigured).
  Future<void> deleteProfilePhoto(String uid);
}

/// Production storage: writes to `users/{uid}/profile.jpg` via [StorageService].
class FirebaseProfileImageStorage implements ProfileImageStorage {
  FirebaseProfileImageStorage(this._storage);

  final StorageService _storage;

  @override
  Future<String?> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    void Function(StorageUploadProgress progress)? onProgress,
  }) {
    return _storage.upload(
      path: StoragePaths.profilePhoto(uid),
      bytes: bytes,
      metadata: StorageMetadata(contentType: contentType),
      onProgress: onProgress,
    );
  }

  @override
  Future<void> deleteProfilePhoto(String uid) =>
      _storage.delete(StoragePaths.profilePhoto(uid));
}

/// The app-wide profile-image storage (swap this binding for tests/alternate
/// backends).
final profileImageStorageProvider = Provider<ProfileImageStorage>(
  (ref) => FirebaseProfileImageStorage(ref.watch(storageServiceProvider)),
);
