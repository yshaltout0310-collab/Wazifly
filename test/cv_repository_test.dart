import 'package:careerbridge/core/services/cv_repository/cv_document.dart';
import 'package:careerbridge/core/services/cv_repository/in_memory_cv_repository.dart';
import 'package:careerbridge/features/cv_builder/domain/cv_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  CvDocument doc(String id, {bool isDefault = false, int minutes = 0}) =>
      CvDocument.create(
        id: id,
        ownerUid: 'u1',
        name: id,
        content: const CvData(fullName: 'A'),
        now: now.add(Duration(minutes: minutes)),
        isDefault: isDefault,
      );

  test('watchCvs excludes soft-deleted, newest-updated first', () async {
    final repo = InMemoryCvRepository();
    await repo.createCv(doc('a', minutes: 1));
    await repo.createCv(doc('b', minutes: 2));
    final gone = doc('c', minutes: 3).softDeleted(now);
    await repo.createCv(gone);

    final list = await repo.watchCvs('u1').first;
    expect(list.map((c) => c.id), ['b', 'a']); // c excluded, newest first
  });

  test('scopes by owner', () async {
    final repo = InMemoryCvRepository();
    await repo.createCv(doc('a'));
    await repo.createCv(CvDocument.create(
        id: 'x', ownerUid: 'other', name: 'x', content: const CvData(), now: now));
    final list = await repo.watchCvs('u1').first;
    expect(list.map((c) => c.id), ['a']);
  });

  test('setDefault enforces a single default', () async {
    final repo = InMemoryCvRepository();
    await repo.createCv(doc('a', isDefault: true));
    await repo.createCv(doc('b'));
    await repo.createCv(doc('c'));

    await repo.setDefault('u1', 'b');
    final list = await repo.watchCvs('u1').first;
    final defaults = list.where((c) => c.isDefault).map((c) => c.id).toList();
    expect(defaults, ['b']);
  });

  test('updateCv merges changes', () async {
    final repo = InMemoryCvRepository();
    await repo.createCv(doc('a'));
    final a = await repo.fetchCv('a');
    await repo.updateCv(a!.renamed('Renamed', now));
    expect((await repo.fetchCv('a'))!.name, 'Renamed');
  });
}
