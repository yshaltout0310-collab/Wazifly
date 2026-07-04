import 'dart:typed_data';

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

/// In-memory [CompanyLogoStorage]: returns [url] (or null to simulate failure).
class FakeCompanyLogoStorage implements CompanyLogoStorage {
  FakeCompanyLogoStorage(this.url);
  final String? url;
  Uint8List? lastBytes;

  @override
  Future<String?> uploadCompanyLogo({
    required String companyId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    lastBytes = bytes;
    return url;
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
}
