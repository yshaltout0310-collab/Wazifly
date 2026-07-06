import 'package:careerbridge/core/services/company/company_repository.dart';
import 'package:careerbridge/core/services/company/in_memory_company_repository.dart';
import 'package:careerbridge/core/services/jobs/employer_jobs_repository.dart';
import 'package:careerbridge/core/services/jobs/in_memory_employer_jobs_repository.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/employer/application/job_editor_controller.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/company.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

const _user = AppUser(uid: 'c1', method: AuthMethod.email, email: 'a@b.co');

({ProviderContainer container, JobEditorController notifier}) _create({
  String? jobId,
  InMemoryEmployerJobsRepository? repo,
}) {
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(FakeAuthRepository(user: _user)),
    companyRepositoryProvider.overrideWithValue(
        InMemoryCompanyRepository(seed: [Company.empty('c1').copyWith(name: 'Acme')])),
    employerJobsRepositoryProvider
        .overrideWithValue(repo ?? InMemoryEmployerJobsRepository()),
  ]);
  addTearDown(container.dispose);
  final sub =
      container.listen(jobEditorControllerProvider(jobId), (_, __) {});
  addTearDown(sub.close);
  final notifier =
      container.read(jobEditorControllerProvider(jobId).notifier);
  return (container: container, notifier: notifier);
}

void main() {
  test('create mode seeds a new draft owned by the signed-in employer', () {
    final (:container, :notifier) = _create();
    final state = container.read(jobEditorControllerProvider(null));
    expect(state.isNew, isTrue);
    expect(state.draft.companyId, 'c1');
    expect(state.draft.ownerUid, 'c1');
    expect(state.dirty, isFalse);
  });

  test('editing a field marks the draft dirty', () {
    final (:container, :notifier) = _create();
    notifier.setTitle('Flutter Engineer');
    expect(container.read(jobEditorControllerProvider(null)).dirty, isTrue);
  });

  test('saveDraft persists a valid draft and flips isNew off', () async {
    final repo = InMemoryEmployerJobsRepository();
    final (:container, :notifier) = _create(repo: repo);
    notifier.setTitle('Flutter Engineer');
    final saved = await notifier.saveDraft();

    expect(saved, isNotNull);
    final state = container.read(jobEditorControllerProvider(null));
    expect(state.isNew, isFalse);
    expect(state.dirty, isFalse);
    expect(state.lastSavedAt, isNotNull);
    expect(await repo.fetchJob(saved!.id), isNotNull);
  });

  test('saveDraft rejects an empty title and reveals errors', () async {
    final (:container, :notifier) = _create();
    final saved = await notifier.saveDraft();
    expect(saved, isNull);
    expect(container.read(jobEditorControllerProvider(null)).showErrors, isTrue);
  });

  test('a second save reuses the same id (update, not a new doc)', () async {
    final repo = InMemoryEmployerJobsRepository();
    final (:container, :notifier) = _create(repo: repo);
    notifier.setTitle('First title');
    final first = await notifier.saveDraft();
    notifier.setTitle('Second title');
    final second = await notifier.saveDraft();

    expect(second!.id, first!.id);
    final all = await repo.watchJobs('c1').first;
    expect(all.length, 1);
    expect(all.single.title, 'Second title');
  });

  test('publishValidation reflects the working draft', () {
    final (:container, :notifier) = _create();
    expect(notifier.publishValidation.isValid, isFalse);
    notifier
      ..setTitle('Senior Flutter Engineer')
      ..setDescription(
          'A detailed description that is well over thirty characters long.')
      ..setSkills(['Flutter'])
      ..setLocation('Doha');
    // Still missing experience + employment type.
    expect(notifier.publishValidation.isValid, isFalse);
  });
}
