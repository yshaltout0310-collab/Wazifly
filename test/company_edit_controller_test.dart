import 'package:careerbridge/core/services/company/company_repository.dart';
import 'package:careerbridge/core/services/company/in_memory_company_repository.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/employer/application/company_edit_controller.dart';
import 'package:careerbridge/features/employer/application/company_providers.dart';
import 'package:careerbridge/features/employer/domain/company_failure.dart';
import 'package:careerbridge/features/employer/domain/company_size.dart';
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

  test('completion recalculates and the dashboard refreshes after a save',
      () async {
    final repo = InMemoryCompanyRepository();
    final c = _container(repo: repo);

    // Keep the reactive company/auth streams subscribed for the whole test.
    final sub = c.listen(companyCompletionProvider, (_, __) {},
        fireImmediately: true);
    addTearDown(sub.close);
    await pumpEventQueue();

    // Baseline: an empty company with only the auth-email contact fallback →
    // 1 of 8 tracked fields → 13% (the exact value the bug got stuck at).
    expect(c.read(companyCompletionProvider), 13);

    await c.read(companyEditControllerProvider.notifier).save(
          const Company(companyId: '', ownerUid: '').copyWith(
            name: 'Acme Corp',
            industry: Industry.technology,
            size: CompanySize.size11_50,
            website: 'https://acme.co',
            headquarters: 'Doha',
            description: 'We build things.',
            contactEmail: 'hr@acme.co',
          ),
        );
    await pumpEventQueue();

    // 7 of 8 filled (only the logo is missing) → the dashboard refreshes to 88%.
    expect(c.read(companyCompletionProvider), 88);
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
