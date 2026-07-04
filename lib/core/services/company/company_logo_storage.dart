import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cloud_storage/cloud_storage_service.dart';

/// Uploads a company's logo and returns its public download URL.
///
/// A thin, testable seam over storage (mirrors `ProfileImageStorage`): the
/// Firebase implementation delegates to [CloudStorageService], and tests bind an
/// in-memory fake. Swap the binding to change where logos live — **no feature
/// changes**.
abstract interface class CompanyLogoStorage {
  /// Uploads [bytes] as the company's logo; returns the download URL, or null
  /// when storage is unconfigured / the upload fails.
  Future<String?> uploadCompanyLogo({
    required String companyId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  });
}

/// Production storage: writes to `companies/{companyId}/logo.jpg` via Firebase
/// Storage.
class FirebaseCompanyLogoStorage implements CompanyLogoStorage {
  FirebaseCompanyLogoStorage(this._storage);

  final CloudStorageService _storage;

  @override
  Future<String?> uploadCompanyLogo({
    required String companyId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) {
    return _storage.uploadBytes(
      path: _storage.companyLogoPath(companyId),
      bytes: bytes,
      contentType: contentType,
    );
  }
}

/// The app-wide company-logo storage (swap this binding for tests/alternate
/// backends).
final companyLogoStorageProvider = Provider<CompanyLogoStorage>(
  (ref) => FirebaseCompanyLogoStorage(ref.watch(cloudStorageServiceProvider)),
);
