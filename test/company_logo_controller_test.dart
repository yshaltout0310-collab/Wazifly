import 'dart:typed_data';

import 'package:careerbridge/core/services/cloud_storage/storage_service.dart';
import 'package:careerbridge/core/services/company/company_logo_storage.dart';
import 'package:careerbridge/core/services/company/company_repository.dart';
import 'package:careerbridge/core/services/company/in_memory_company_repository.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/employer/application/company_logo_controller.dart';
import 'package:careerbridge/features/employer/domain/company_failure.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

/// In-memory [CompanyLogoStorage]: returns [url] (or null to simulate failure),
/// emits progress, and records deletes.
class FakeCompanyLogoStorage implements CompanyLogoStorage {
  FakeCompanyLogoStorage(this.url);
  final String? url;
  Uint8List? lastBytes;
  bool deleted = false;
  final List<double> progress = [];

  @override
  Future<String?> uploadCompanyLogo({
    required String companyId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    void Function(StorageUploadProgress progress)? onProgress,
  }) async {
    lastBytes = bytes;
    onProgress?.call(const StorageUploadProgress(bytesTransferred: 1, totalBytes: 2));
    onProgress?.call(const StorageUploadProgress(bytesTransferred: 2, totalBytes: 2));
    progress.addAll([0.5, 1.0]);
    return url;
  }

  @override
  Future<void> deleteCompanyLogo(String companyId) async {
    deleted = true;
  }
}

const _user = AppUser(uid: 'c1', method: AuthMethod.email);

ProviderContainer _container({
  required String? uploadUrl,
  AppUser? user = _user,
  InMemoryCompanyRepository? repo,
}) {
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(FakeAuthRepository(user: user)),
    companyLogoStorageProvider
        .overrideWithValue(FakeCompanyLogoStorage(uploadUrl)),
    companyRepositoryProvider
        .overrideWithValue(repo ?? InMemoryCompanyRepository()),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  final bytes = Uint8List.fromList([1, 2, 3, 4]);

  test('uploads then persists the logo URL to the company', () async {
    final repo = InMemoryCompanyRepository();
    final c = _container(uploadUrl: 'https://img/logo.jpg', repo: repo);
    await c
        .read(companyLogoControllerProvider.notifier)
        .uploadBytes(bytes, fileName: 'logo.png');

    expect(c.read(companyLogoControllerProvider).status, LogoStatus.idle);
    expect((await repo.fetchCompany('c1'))?.logoUrl, 'https://img/logo.jpg');
  });

  test('a null upload URL surfaces a logo-upload failure', () async {
    final c = _container(uploadUrl: null);
    await c.read(companyLogoControllerProvider.notifier).uploadBytes(bytes);
    final state = c.read(companyLogoControllerProvider);
    expect(state.status, LogoStatus.error);
    expect(state.failure, CompanyFailure.logoUploadFailed);
  });

  test('signed-out users cannot upload', () async {
    final c = _container(uploadUrl: 'https://x', user: null);
    await c.read(companyLogoControllerProvider.notifier).uploadBytes(bytes);
    expect(c.read(companyLogoControllerProvider).failure,
        CompanyFailure.notSignedIn);
  });

  test('upload reports progress and ends idle', () async {
    final storage = FakeCompanyLogoStorage('https://img/logo.jpg');
    final c = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository(user: _user)),
      companyLogoStorageProvider.overrideWithValue(storage),
      companyRepositoryProvider.overrideWithValue(InMemoryCompanyRepository()),
    ]);
    addTearDown(c.dispose);

    await c.read(companyLogoControllerProvider.notifier).uploadBytes(bytes);
    expect(storage.progress, [0.5, 1.0]);
    expect(c.read(companyLogoControllerProvider).status, LogoStatus.idle);
  });

  test('removeLogo deletes from storage and clears the URL', () async {
    final storage = FakeCompanyLogoStorage('https://img/logo.jpg');
    final repo = InMemoryCompanyRepository();
    final c = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository(user: _user)),
      companyLogoStorageProvider.overrideWithValue(storage),
      companyRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);

    await c.read(companyLogoControllerProvider.notifier).uploadBytes(bytes);
    await c.read(companyLogoControllerProvider.notifier).removeLogo();

    expect(storage.deleted, isTrue);
    expect((await repo.fetchCompany('c1'))?.logoUrl ?? '', '');
    expect(c.read(companyLogoControllerProvider).status, LogoStatus.idle);
  });
}
