import 'dart:typed_data';

/// Progress of an in-flight upload — a plain value type so no vendor snapshot
/// type crosses the [StorageService] boundary.
class StorageUploadProgress {
  const StorageUploadProgress({
    required this.bytesTransferred,
    required this.totalBytes,
  });

  final int bytesTransferred;
  final int totalBytes;

  /// Fraction complete in `[0, 1]` (0 when the total is unknown/zero).
  double get fraction =>
      totalBytes <= 0 ? 0 : (bytesTransferred / totalBytes).clamp(0.0, 1.0);

  static const StorageUploadProgress none =
      StorageUploadProgress(bytesTransferred: 0, totalBytes: 0);
}

/// Optional object metadata for an upload. Only [contentType] is used today;
/// [cacheControl] and [customMetadata] are accepted now so the interface never
/// has to change when they're needed (forward-compat, per the M1 additions).
class StorageMetadata {
  const StorageMetadata({
    this.contentType,
    this.cacheControl,
    this.customMetadata,
  });

  final String? contentType;
  final String? cacheControl;
  final Map<String, String>? customMetadata;
}

/// Provider-agnostic, low-level file store (the single Firebase Storage
/// boundary). Only `FirebaseStorageService` imports `firebase_storage`; swap the
/// backend by rebinding `storageServiceProvider` — no feature changes.
///
/// Every method is **best-effort and non-throwing**: it degrades to a null/no-op
/// when storage is unconfigured or a call fails, so telemetry/media issues never
/// break the app (the M1 telemetry principle).
abstract interface class StorageService {
  /// Uploads [bytes] to [path]; returns the download URL, or null when
  /// unconfigured / on failure. [onProgress] (if given) is called as bytes
  /// transfer.
  Future<String?> upload({
    required String path,
    required Uint8List bytes,
    StorageMetadata? metadata,
    void Function(StorageUploadProgress progress)? onProgress,
  });

  /// Deletes the object at [path] (no-op when unconfigured / already gone).
  Future<void> delete(String path);

  /// Returns the download URL for [path], or null when unconfigured / missing.
  Future<String?> downloadUrl(String path);
}
