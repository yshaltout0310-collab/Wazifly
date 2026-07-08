import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cloud_storage/firebase_storage_service.dart';
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
/// [StorageService].
class FirebaseCompanyLogoStorage implements CompanyLogoStorage {
  FirebaseCompanyLogoStorage(this._storage);

  final StorageService _storage;

  @override
  Future<String?> uploadCompanyLogo({
    required String companyId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    void Function(StorageUploadProgress progress)? onProgress,
  }) {
    return _storage.upload(
      path: StoragePaths.companyLogo(companyId),
      bytes: bytes,
      metadata: StorageMetadata(contentType: contentType),
      onProgress: onProgress,
    );
  }

  @override
  Future<void> deleteCompanyLogo(String companyId) =>
      _storage.delete(StoragePaths.companyLogo(companyId));
}

/// The app-wide company-logo storage (swap this binding for tests/alternate
/// backends).
final companyLogoStorageProvider = Provider<CompanyLogoStorage>(
  (ref) => FirebaseCompanyLogoStorage(ref.watch(storageServiceProvider)),
);
