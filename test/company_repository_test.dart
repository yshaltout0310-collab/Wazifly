import 'package:careerbridge/core/services/company/in_memory_company_repository.dart';
import 'package:careerbridge/shared/models/company.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('watchCompany emits current value then updates', () async {
    final repo = InMemoryCompanyRepository();
    final events = <Company?>[];
    final sub = repo.watchCompany('c1').listen(events.add);
    await Future<void>.delayed(Duration.zero);

    await repo.saveCompany(
        Company.empty('c1').copyWith(name: 'Acme'));
    await Future<void>.delayed(Duration.zero);

    await sub.cancel();
    expect(events.first, isNull);
    expect(events.last?.name, 'Acme');
    expect((await repo.fetchCompany('c1'))?.name, 'Acme');
  });

  test('ensureCompany seeds identity once and is idempotent', () async {
    final repo = InMemoryCompanyRepository();
    await repo.ensureCompany('c1', email: 'hi@acme.co', name: 'Acme');
    final seeded = await repo.fetchCompany('c1');
    expect(seeded?.ownerUid, 'c1');
    expect(seeded?.contactEmail, 'hi@acme.co');
    expect(seeded?.name, 'Acme');

    // Edit, then ensure again — must not clobber the edit.
    await repo.saveCompany(seeded!.copyWith(name: 'Acme Corp'));
    await repo.ensureCompany('c1', email: 'other@x.co', name: 'Other');
    expect((await repo.fetchCompany('c1'))?.name, 'Acme Corp');
  });

  test('setLogoUrl persists the logo', () async {
    final repo = InMemoryCompanyRepository();
    await repo.setLogoUrl('c1', 'https://acme.co/logo.png');
    expect((await repo.fetchCompany('c1'))?.logoUrl, 'https://acme.co/logo.png');
  });
}
