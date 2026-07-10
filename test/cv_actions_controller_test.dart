import 'package:careerbridge/core/services/cv_repository/cv_document.dart';
import 'package:careerbridge/core/services/cv_repository/cv_repository.dart';
import 'package:careerbridge/core/services/cv_repository/in_memory_cv_repository.dart';
import 'package:careerbridge/features/cv_builder/domain/cv_data.dart';
import 'package:careerbridge/features/cv_repository/application/cv_actions_controller.dart';
import 'package:careerbridge/features/cv_repository/domain/cv_repository_failure.dart';
import 'package:careerbridge/features/resume_analyzer/domain/resume_analysis.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

void main() {
  const user = AppUser(uid: 'u1', method: AuthMethod.email, email: 'a@b.com');

  late InMemoryCvRepository repo;
  late ProviderContainer c;

  Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 5));

  setUp(() {
    repo = InMemoryCvRepository();
    c = ProviderContainer(overrides: [
      fakeAuthOverride(user: user),
      cvRepositoryProvider.overrideWithValue(repo),
    ]);
    c.listen(cvDocumentsProvider, (_, __) {}); // keep the stream alive
    addTearDown(c.dispose);
  });

  CvActionsController ctrl() => c.read(cvActionsControllerProvider.notifier);
  Future<List<CvDocument>> current() => repo.watchCvs('u1').first;

  ResumeAnalysis analysis(int ats) => ResumeAnalysis(
        atsScore: ats,
        summary: 'sum',
        strengths: const [],
        weaknesses: const [],
        missingSkills: const [],
        grammarIssues: const [],
        improvementSuggestions: const [],
      );

  PendingImport pending(String name, {int ats = 70}) => PendingImport(
        name: name,
        content: const CvData(fullName: 'Imported'),
        analysis: analysis(ats),
        importHash: 'hash-$name',
      );

  test('first CV is auto-default; the second is not', () async {
    await ctrl().createFromProfile(name: 'First');
    await pump();
    await ctrl().createFromProfile(name: 'Second');
    await pump();

    final list = await current();
    expect(list.length, 2);
    expect(list.where((d) => d.isDefault).length, 1);
    expect(list.firstWhere((d) => d.name == 'First').isDefault, isTrue);
    expect(list.firstWhere((d) => d.name == 'Second').isDefault, isFalse);
  });

  test('deleting the last active CV is blocked with a localized failure', () async {
    await ctrl().createFromProfile(name: 'Only');
    await pump();
    final only = (await current()).single;

    final ok = await ctrl().delete(only);
    expect(ok, isFalse);
    expect(c.read(cvActionsControllerProvider).failure,
        CvActionFailure.lastActiveCv);
    expect((await current()).length, 1); // still there
  });

  test('deleting the default auto-promotes another active CV', () async {
    await ctrl().createFromProfile(name: 'First'); // becomes default
    await pump();
    await ctrl().createFromProfile(name: 'Second');
    await pump();

    final first = (await current()).firstWhere((d) => d.name == 'First');
    final ok = await ctrl().delete(first);
    await pump();
    expect(ok, isTrue);

    final remaining = await current();
    expect(remaining.length, 1);
    expect(remaining.single.name, 'Second');
    expect(remaining.single.isDefault, isTrue); // promoted
  });

  test('import as new: first is default, source imported, analysis attached',
      () async {
    final cv = await ctrl().confirmImportAsNew(pending('Resume', ats: 88));
    await pump();
    expect(cv, isNotNull);
    final stored = (await current()).single;
    expect(stored.source, CvSource.imported);
    expect(stored.isDefault, isTrue);
    expect(stored.atsScore, 88);
    expect(stored.importHash, 'hash-Resume');
  });

  test('import replace updates content + analysis and bumps version', () async {
    final existing = await ctrl().confirmImportAsNew(pending('R1', ats: 50));
    await pump();
    await ctrl().confirmImportReplace(existing!, pending('R1', ats: 95));
    await pump();

    final stored = (await current()).single;
    expect(stored.atsScore, 95);
    expect(stored.version, greaterThan(1));
  });

  test('archive protection: cannot archive the last active CV', () async {
    await ctrl().createFromProfile(name: 'Only');
    await pump();
    final only = (await current()).single;
    final ok = await ctrl().archive(only);
    expect(ok, isFalse);
    expect((await current()).single.isActive, isTrue);
  });
}
