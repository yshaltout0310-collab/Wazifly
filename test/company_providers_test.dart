import 'package:careerbridge/core/services/company/company_repository.dart';
import 'package:careerbridge/core/services/company/in_memory_company_repository.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/employer/application/company_providers.dart';
import 'package:careerbridge/features/employer/domain/industry.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/company.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

const _user = AppUser(
    uid: 'c1', method: AuthMethod.email, email: 'owner@acme.co');

ProviderContainer _container({List<Company> seed = const []}) {
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(FakeAuthRepository(user: _user)),
    companyRepositoryProvider
        .overrideWithValue(InMemoryCompanyRepository(seed: seed)),
  ]);
  addTearDown(container.dispose);
  return container;
}

/// Keeps the provider chain alive and pumps the event loop until the
/// auth-gated company stream has resolved.
Future<Company?> _resolve(ProviderContainer c, {bool wantStored = false}) async {
  c.listen(companyProvider, (_, __) {}); // keep the stream alive
  c.listen(currentCompanyProvider, (_, __) {});
  for (var i = 0; i < 50; i++) {
    await Future<void>.delayed(Duration.zero);
    final co = c.read(currentCompanyProvider);
    final ready = co != null && (!wantStored || co.name != null);
    if (ready) break;
  }
  return c.read(currentCompanyProvider);
}

void main() {
  test('currentCompany falls back to an empty company with the auth email',
      () async {
    final c = _container();
    final company = await _resolve(c);
    expect(company?.companyId, 'c1');
    expect(company?.contactEmail, 'owner@acme.co'); // auth fallback
    // Only the fallback contact email is filled → 1 of 8 tracked fields.
    expect(c.read(companyCompletionProvider), 13);
  });

  test('currentCompany surfaces the stored document + completion', () async {
    final stored = Company.empty('c1').copyWith(
      name: 'Acme',
      industry: Industry.technology,
      website: 'https://acme.co',
      contactEmail: 'jobs@acme.co',
    );
    final c = _container(seed: [stored]);
    final company = await _resolve(c, wantStored: true);
    expect(company?.name, 'Acme');
    expect(company?.contactEmail, 'jobs@acme.co'); // stored value kept
    expect(c.read(companyCompletionProvider), greaterThan(0));
  });
}
