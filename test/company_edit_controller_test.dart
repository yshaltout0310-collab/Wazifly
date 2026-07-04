import 'package:careerbridge/core/services/company/company_repository.dart';
import 'package:careerbridge/core/services/company/in_memory_company_repository.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/employer/application/company_edit_controller.dart';
import 'package:careerbridge/features/employer/domain/company_failure.dart';
import 'package:careerbridge/features/employer/domain/industry.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/company.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

const _user = AppUser(uid: 'c1', method: AuthMethod.email, email: 'a@b.co');

ProviderContainer _container({
  AppUser? user = _user,
  InMemoryCompanyRepository? repo,
}) {
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(FakeAuthRepository(user: user)),
    companyRepositoryProvider
        .overrideWithValue(repo ?? InMemoryCompanyRepository()),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('save persists to the repo, keying by uid + deriving a slug', () async {
    final repo = InMemoryCompanyRepository();
    final c = _container(repo: repo);
    final ok = await c.read(companyEditControllerProvider.notifier).save(
          const Company(companyId: '', ownerUid: '')
              .copyWith(name: 'Acme Corp', industry: Industry.technology),
        );
    expect(ok, isTrue);
    expect(c.read(companyEditControllerProvider).status,
        CompanyEditStatus.success);

    final stored = await repo.fetchCompany('c1');
    expect(stored?.companyId, 'c1');
    expect(stored?.ownerUid, 'c1');
    expect(stored?.name, 'Acme Corp');
    expect(stored?.companySlug, 'acme-corp'); // auto-derived
  });

  test('does not overwrite an existing slug', () async {
    final repo = InMemoryCompanyRepository();
    final c = _container(repo: repo);
    await c.read(companyEditControllerProvider.notifier).save(
          const Company(companyId: '', ownerUid: '')
              .copyWith(name: 'Acme', companySlug: 'custom-slug'),
        );
    expect((await repo.fetchCompany('c1'))?.companySlug, 'custom-slug');
  });

  test('signed-out users cannot save', () async {
    final c = _container(user: null);
    final ok = await c
        .read(companyEditControllerProvider.notifier)
        .save(Company.empty('c1'));
    expect(ok, isFalse);
    expect(c.read(companyEditControllerProvider).failure,
        CompanyFailure.notSignedIn);
  });
}
