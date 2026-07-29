import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cloud_storage/image_optimizer.dart';
import '../cloud_storage/storage_paths.dart';
import '../cloud_storage/storage_service.dart';

/// Uploads / removes a company's logo — the company-media repository.
///
/// A thin, testable seam over [StorageService] (mirrors `ProfileImageStorage`):
/// the Firebase-backed implementation delegates to it, and tests bind an
/// in-memory fake. Swap the binding to change where logos live — **no feature
/// changes**.
abstract interface class CompanyLogoStorage {
  /// Uploads [bytes] as the company's logo; returns the download URL, or null
  /// when storage is unconfigured / the upload fails. [onProgress] reports
  /// upload progress.
  Future<String?> uploadCompanyLogo({
    required String companyId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    void Function(StorageUploadProgress progress)? onProgress,
  });

  /// Removes the company's logo (no-op when absent / unconfigured).
  Future<void> deleteCompanyLogo(String companyId);
}

/// Production storage: writes to `companies/{companyId}/logo.jpg` via
/// [StorageService], downscaling the image first via [ImageOptimizer].
class FirebaseCompanyLogoStorage implements CompanyLogoStorage {
  FirebaseCompanyLogoStorage(this._storage, [ImageOptimizer? optimizer])
      : _optimizer = optimizer ?? const NoopImageOptimizer();

  final StorageService _storage;
  final ImageOptimizer _optimizer;

  @override
  Future<String?> uploadCompanyLogo({
    required String companyId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    void Function(StorageUploadProgress progress)? onProgress,
  }) async {
    final optimized = await _optimizer.optimize(bytes,
        fallbackContentType: contentType);
    return _storage.upload(
      path: StoragePaths.companyLogo(companyId),
      bytes: optimized.bytes,
      metadata: StorageMetadata(contentType: optimized.contentType),
      onProgress: onProgress,
    );
  }

  @override
  Future<void> deleteCompanyLogo(String companyId) =>
      _storage.delete(StoragePaths.companyLogo(companyId));
}

/// Stores a company logo as a base64 `data:` URI embedded directly in the
/// company's Firestore document (the caller persists it via `setLogoUrl`) — **no
/// Cloud Storage bucket required**.
///
/// Why this is the default: the Firebase project ships without a provisioned
/// Storage bucket (and `storage.rules` isn't deployed), so the Cloud-Storage
/// upload path always failed on-device ("upload failed"). A logo is tiny once
/// downscaled, so embedding it keeps the feature fully working on the free tier
/// while reusing the existing [CompanyLogoStorage] seam, the `logoUrl` field, and
/// the display-side [AppImage] provider (which renders `data:` URIs). The
/// Cloud-Storage-backed [FirebaseCompanyLogoStorage] remains available to rebind
/// once a bucket is provisioned.
class DataUriCompanyLogoStorage implements CompanyLogoStorage {
  DataUriCompanyLogoStorage([ImageOptimizer? optimizer])
      : _optimizer = optimizer ?? const UiImageOptimizer();

  final ImageOptimizer _optimizer;

  /// Logos render in a ≤104 px box, so a 256 px longest edge is plenty and keeps
  /// the encoded string small.
  static const int _maxDimension = 256;

  /// Safety ceiling (~700 KB) for the encoded URI, leaving headroom under
  /// Firestore's 1 MB document limit for the rest of the company fields.
  static const int _maxEncodedChars = 700 * 1024;

  @override
  Future<String?> uploadCompanyLogo({
    required String companyId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    void Function(StorageUploadProgress progress)? onProgress,
  }) async {
    onProgress?.call(
        StorageUploadProgress(bytesTransferred: 0, totalBytes: bytes.length));
    final optimized = await _optimizer.optimize(
      bytes,
      maxDimension: _maxDimension,
      fallbackContentType: contentType,
    );
    final uri =
        'data:${optimized.contentType};base64,${base64Encode(optimized.bytes)}';
    // Too large to embed safely — signal failure so the UI shows an error
    // instead of writing a document Firestore would reject.
    if (uri.length > _maxEncodedChars) return null;
    onProgress?.call(StorageUploadProgress(
        bytesTransferred: bytes.length, totalBytes: bytes.length));
    return uri;
  }

  @override
  Future<void> deleteCompanyLogo(String companyId) async {
    // Nothing to remove from external storage — the logo lives on the company
    // document and is cleared by the caller via setLogoUrl(companyId, '').
  }
}

/// The app-wide company-logo storage (swap this binding for tests/alternate
/// backends). Defaults to the Firestore-embedded [DataUriCompanyLogoStorage] so
/// logo upload works without a provisioned Cloud Storage bucket.
final companyLogoStorageProvider = Provider<CompanyLogoStorage>(
  (ref) => DataUriCompanyLogoStorage(ref.watch(imageOptimizerProvider)),
);
