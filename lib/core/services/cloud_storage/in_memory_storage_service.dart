import 'dart:typed_data';

import 'storage_service.dart';

/// Session-scoped [StorageService] for tests / offline runs: records uploads and
/// deletes in memory and emits synthetic progress. Returns `memory://<path>`
/// URLs so callers can assert a non-null result without a live backend.
class InMemoryStorageService implements StorageService {
  InMemoryStorageService({this.failUploads = false});

  /// When true, [upload] returns null (to exercise upload-failure paths).
  bool failUploads;

  final Map<String, Uint8List> files = {};
  final List<String> deleted = [];
  StorageMetadata? lastMetadata;

  @override
  Future<String?> upload({
    required String path,
    required Uint8List bytes,
    StorageMetadata? metadata,
    void Function(StorageUploadProgress progress)? onProgress,
  }) async {
    if (failUploads) return null;
    lastMetadata = metadata;
    onProgress?.call(
        StorageUploadProgress(bytesTransferred: bytes.length ~/ 2, totalBytes: bytes.length));
    files[path] = bytes;
    onProgress?.call(
        StorageUploadProgress(bytesTransferred: bytes.length, totalBytes: bytes.length));
    return 'memory://$path';
  }

  @override
  Future<void> delete(String path) async {
    files.remove(path);
    deleted.add(path);
  }

  @override
  Future<String?> downloadUrl(String path) async =>
      files.containsKey(path) ? 'memory://$path' : null;
}
