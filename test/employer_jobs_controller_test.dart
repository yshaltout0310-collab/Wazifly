import 'package:careerbridge/core/services/jobs/employer_jobs_repository.dart';
import 'package:careerbridge/core/services/jobs/in_memory_employer_jobs_repository.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/employer/application/employer_jobs_controller.dart';
import 'package:careerbridge/features/employer/domain/job_status.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/job_posting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

const _user = AppUser(uid: 'c1', method: AuthMethod.email, email: 'a@b.co');

JobPosting _draft(String id) => JobPosting(
      id: id,
      companyId: 'c1',
      ownerUid: 'c1',
      title: 'Job $id',
      status: JobStatus.draft,
      updatedAt: DateTime(2026, 7, 1),
    );

/// Rejects every write so the optimistic controller must roll back.
class _ThrowingRepo implements EmployerJobsRepository {
  @override
  Future<JobPosting> createJob(JobPosting posting) async => throw 'boom';
  @override
  Future<void> updateJob(JobPosting posting) async => throw 'boom';
  @override
  Future<JobPosting?> fetchJob(String id) async => null;
  @override
  Stream<List<JobPosting>> watchJobs(String companyId) =>
      Stream.value(const []);
}

ProviderContainer _container(EmployerJobsRepository repo) {
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(FakeAuthRepository(user: _user)),
    employerJobsRepositoryProvider.overrideWithValue(repo),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('publish persists the transition and clears the overlay', () async {
    final repo = InMemoryEmployerJobsRepository(seed: [_draft('a')]);
    final c = _container(repo);
    await c.read(employerJobsControllerProvider.notifier).publish(_draft('a'));

    expect((await repo.fetchJob('a'))?.status, JobStatus.published);
    final state = c.read(employerJobsControllerProvider);
    expect(state.failure, isNull);
    expect(state.overrides, isEmpty);
    expect(state.pending, isEmpty);
  });

  test('a write failure rolls back the overlay and surfaces a failure',
      () async {
    final c = _container(_ThrowingRepo());
    await c.read(employerJobsControllerProvider.notifier).publish(_draft('a'));

    final state = c.read(employerJobsControllerProvider);
    expect(state.failure, JobsActionFailure.unknown);
    expect(state.overrides, isEmpty);
    expect(state.removedIds, isEmpty);
    expect(state.pending, isEmpty);
  });

  test('softDelete marks the doc deleted', () async {
    final repo = InMemoryEmployerJobsRepository(seed: [_draft('a')]);
    final c = _container(repo);
    await c.read(employerJobsControllerProvider.notifier).softDelete(_draft('a'));

    expect((await repo.fetchJob('a'))?.isDeleted, isTrue);
    expect(c.read(employerJobsControllerProvider).failure, isNull);
  });

  test('duplicate creates a fresh draft copy in the repository', () async {
    final published =
        _draft('a').copyWith(status: JobStatus.published, title: 'Original');
    final repo = InMemoryEmployerJobsRepository(seed: [published]);
    final c = _container(repo);
    final copy =
        await c.read(employerJobsControllerProvider.notifier).duplicate(published);

    expect(copy.status, JobStatus.draft);
    expect(copy.title, 'Original (Copy)');
    expect(await repo.fetchJob(copy.id), isNotNull);
  });

  test('an illegal transition is a no-op', () async {
    final repo = InMemoryEmployerJobsRepository(seed: [_draft('a')]);
    final c = _container(repo);
    // draft cannot go straight to archived.
    await c
        .read(employerJobsControllerProvider.notifier)
        .archive(_draft('a'));
    expect((await repo.fetchJob('a'))?.status, JobStatus.draft);
  });

  test('clearFailure resets the surfaced failure', () async {
    final c = _container(_ThrowingRepo());
    final notifier = c.read(employerJobsControllerProvider.notifier);
    await notifier.publish(_draft('a'));
    expect(c.read(employerJobsControllerProvider).failure, isNotNull);
    notifier.clearFailure();
    expect(c.read(employerJobsControllerProvider).failure, isNull);
  });
}
