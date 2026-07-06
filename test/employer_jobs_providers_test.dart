import 'package:careerbridge/core/services/jobs/employer_jobs_repository.dart';
import 'package:careerbridge/core/services/jobs/in_memory_employer_jobs_repository.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/employer/application/employer_jobs_controller.dart';
import 'package:careerbridge/features/employer/application/employer_jobs_providers.dart';
import 'package:careerbridge/features/employer/domain/job_status.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/job_posting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

const _user = AppUser(uid: 'c1', method: AuthMethod.email, email: 'a@b.co');

JobPosting _job(String id, String title, JobStatus status, DateTime updated,
        {List<String> skills = const []}) =>
    JobPosting(
      id: id,
      companyId: 'c1',
      ownerUid: 'c1',
      title: title,
      status: status,
      requiredSkills: skills,
      updatedAt: updated,
    );

Future<(ProviderContainer, InMemoryEmployerJobsRepository)> _seeded() async {
  final repo = InMemoryEmployerJobsRepository(seed: [
    _job('a', 'Flutter Engineer', JobStatus.published, DateTime(2026, 7, 1),
        skills: ['Flutter']),
    _job('b', 'Backend Developer', JobStatus.draft, DateTime(2026, 7, 5)),
    _job('c', 'Data Analyst', JobStatus.published, DateTime(2026, 7, 3)),
  ]);
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(FakeAuthRepository(user: _user)),
    employerJobsRepositoryProvider.overrideWithValue(repo),
  ]);
  addTearDown(container.dispose);
  container.listen(employerJobsProvider, (_, __) {});
  await container.read(employerJobsProvider.future);
  // The repo's `yield snapshot; yield* broadcast` stream subscribes to the
  // broadcast one microtask after the first value; let that settle so later
  // re-emits aren't dropped (broadcast streams drop events with no listener).
  await Future<void>.delayed(const Duration(milliseconds: 20));
  return (container, repo);
}

void main() {
  test('visible list sorts by most-recently-updated by default', () async {
    final (c, _) = await _seeded();
    final ids =
        c.read(filteredEmployerJobsProvider).map((j) => j.id).toList();
    expect(ids, ['b', 'c', 'a']);
  });

  test('status filter keeps only the selected statuses', () async {
    final (c, _) = await _seeded();
    c.read(employerJobsFilterProvider.notifier).toggleStatus(JobStatus.published);
    final ids =
        c.read(filteredEmployerJobsProvider).map((j) => j.id).toList();
    expect(ids, ['c', 'a']);
  });

  test('text search matches title + skills', () async {
    final (c, _) = await _seeded();
    c.read(employerJobsFilterProvider.notifier).updateText('flutter');
    final ids =
        c.read(filteredEmployerJobsProvider).map((j) => j.id).toList();
    expect(ids, ['a']);
  });

  test('sort by title orders alphabetically', () async {
    final (c, _) = await _seeded();
    c.read(employerJobsFilterProvider.notifier).setSort(JobSort.title);
    final ids =
        c.read(filteredEmployerJobsProvider).map((j) => j.id).toList();
    expect(ids, ['b', 'c', 'a']); // Backend, Data, Flutter
  });

  test('stats count per status', () async {
    final (c, _) = await _seeded();
    final stats = c.read(employerJobsStatsProvider);
    expect(stats.total, 3);
    expect(stats.published, 2);
    expect(stats.drafts, 1);
  });

  test('a soft-delete removes the posting from the visible list', () async {
    final (c, repo) = await _seeded();
    final job = c.read(employerJobByIdProvider('a'))!;
    await c.read(employerJobsControllerProvider.notifier).softDelete(job);
    // The repository must have marked it deleted...
    expect((await repo.fetchJob('a'))?.isDeleted, isTrue);
    // ...and the stream re-emits the list without it.
    for (var i = 0;
        i < 50 && c.read(employerJobByIdProvider('a')) != null;
        i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(c.read(employerJobByIdProvider('a')), isNull);
  });
}
