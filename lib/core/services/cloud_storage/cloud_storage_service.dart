import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_service.dart';

/// Thin wrapper over Firebase Storage for user media (profile photos, resumes).
///
/// Plumbing is prepared this phase; features that upload files arrive later.
/// No-ops when Firebase isn't configured.
class CloudStorageService {
  CloudStorageService([FirebaseStorage? storage]) : _storage = storage;

  final FirebaseStorage? _storage;

  bool get _ready => FirebaseService.instance.isReady;

  FirebaseStorage get _ref => _storage ?? FirebaseStorage.instance;

  /// Uploads raw bytes to [path] and returns the download URL (or null when
  /// unconfigured / on failure).
  Future<String?> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    if (!_ready) return null;
    try {
      final ref = _ref.ref(path);
      final task = await ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
      return task.ref.getDownloadURL();
    } catch (e) {
      debugPrint('[CloudStorageService] uploadBytes failed: $e');
      return null;
    }
  }

  String profilePhotoPath(String uid) => 'users/$uid/profile.jpg';
  String resumePath(String uid, String fileName) =>
      'users/$uid/resumes/$fileName';
}

final cloudStorageServiceProvider = Provider<CloudStorageService>(
  (ref) => CloudStorageService(),
);
