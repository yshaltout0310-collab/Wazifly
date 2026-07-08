import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_service.dart';
import 'storage_service.dart';

/// Firebase Storage implementation of [StorageService] — the **only** file that
/// imports `firebase_storage`. No-ops (returns null) whenever Firebase isn't
/// ready, so an unprovisioned bucket degrades gracefully instead of throwing.
class FirebaseStorageService implements StorageService {
  FirebaseStorageService([FirebaseStorage? storage]) : _storage = storage;

  final FirebaseStorage? _storage;

  bool get _ready => FirebaseService.instance.isReady;
  FirebaseStorage get _ref => _storage ?? FirebaseStorage.instance;

  @override
  Future<String?> upload({
    required String path,
    required Uint8List bytes,
    StorageMetadata? metadata,
    void Function(StorageUploadProgress progress)? onProgress,
  }) async {
    if (!_ready) return null;
    try {
      final ref = _ref.ref(path);
      final task = ref.putData(bytes, _settable(metadata));
      if (onProgress != null) {
        task.snapshotEvents.listen(
          (s) => onProgress(StorageUploadProgress(
            bytesTransferred: s.bytesTransferred,
            totalBytes: s.totalBytes,
          )),
          onError: (_) {/* progress is best-effort */},
        );
      }
      final snap = await task;
      return snap.ref.getDownloadURL();
    } catch (e) {
      debugPrint('[StorageService] upload failed ($path): $e');
      return null;
    }
  }

  @override
  Future<void> delete(String path) async {
    if (!_ready) return;
    try {
      await _ref.ref(path).delete();
    } catch (e) {
      // A missing object (object-not-found) is a benign no-op.
      debugPrint('[StorageService] delete skipped ($path): $e');
    }
  }

  @override
  Future<String?> downloadUrl(String path) async {
    if (!_ready) return null;
    try {
      return await _ref.ref(path).getDownloadURL();
    } catch (e) {
      debugPrint('[StorageService] downloadUrl failed ($path): $e');
      return null;
    }
  }

  SettableMetadata? _settable(StorageMetadata? m) => m == null
      ? null
      : SettableMetadata(
          contentType: m.contentType,
          cacheControl: m.cacheControl,
          customMetadata: m.customMetadata,
        );
}

/// The app-wide storage backend (swap this binding for tests / alternate
/// providers). Defaults to Firebase Storage, which self-gates on Firebase
/// readiness.
final storageServiceProvider = Provider<StorageService>(
  (ref) => FirebaseStorageService(),
);
