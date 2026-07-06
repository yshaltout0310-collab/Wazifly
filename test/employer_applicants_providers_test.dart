import 'package:careerbridge/core/services/applications/employer_applicants_repository.dart';
import 'package:careerbridge/core/services/applications/in_memory_employer_applicants_repository.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/employer/application/employer_applicants_providers.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/applicant_snapshot.dart';
import 'package:careerbridge/shared/models/application.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

const _user = AppUser(uid: 'emp1', method: AuthMethod.email, email: 'e@b.co');

Application _app(
  String id, {
  required String jobId,
  required String jobTitle,
  required ApplicationStatus status,
  required DateTime updated,
  required String name,
  int? match,
}) =>
    Application(
      id: id,
      jobId: jobId,
      jobTitle: jobTitle,
      company: 'Acme',
      location: 'Doha',
      status: status,
      appliedAt: DateTime(2026, 7, 1),
      updatedAt: updated,
      history: [ApplicationEvent(status: status, at: updated)],
      applicantUid: 'seeker_$id',
      ownerUid: 'emp1',
      applicant: ApplicantSnapshot(name: name, matchScore: match),
    );

Future<ProviderContainer> _seeded() async {
  final repo = InMemoryEmployerApplicantsRepository(seed: [
    _app('a',
        jobId: 'j1',
        jobTitle: 'Flutter Engineer',
        status: ApplicationStatus.pending,
        updated: DateTime(2026, 7, 5),
        name: 'Sara',
        match: 92),
    _app('b',
        jobId: 'j1',
        jobTitle: 'Flutter Engineer',
        status: ApplicationStatus.interview,
        updated: DateTime(2026, 7, 6),
        name: 'Omar',
        match: 70),
    _app('c',
        jobId: 'j2',
        jobTitle: 'Backend Developer',
        status: ApplicationStatus.accepted,
        updated: DateTime(2026, 7, 4),
        name: 'Lina',
        match: 55),
  ]);
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(FakeAuthRepository(user: _user)),
    employerApplicantsRepositoryProvider.overrideWithValue(repo),
  ]);
  addTearDown(container.dispose);
  container.listen(employerApplicantsProvider, (_, __) {});
  await container.read(employerApplicantsProvider.future);
  return container;
}

void main() {
  test('grouped by job, jobs ordered by most-recent activity', () async {
    final c = await _seeded();
    final groups = c.read(groupedApplicantsProvider);
    expect(groups.map((g) => g.jobId), ['j1', 'j2']); // j1 has the newest
    expect(groups.first.count, 2);
    expect(groups.last.jobTitle, 'Backend Developer');
  });

  test('status filter narrows the list', () async {
    final c = await _seeded();
    c
        .read(employerApplicantsFilterProvider.notifier)
        .toggleStatus(ApplicationStatus.interview);
    expect(c.read(filteredApplicantsProvider).map((a) => a.id), ['b']);
  });

  test('text search matches applicant name', () async {
    final c = await _seeded();
    c.read(employerApplicantsFilterProvider.notifier).updateText('sara');
    expect(c.read(filteredApplicantsProvider).map((a) => a.id), ['a']);
  });

  test('sort by match score orders desc', () async {
    final c = await _seeded();
    c
        .read(employerApplicantsFilterProvider.notifier)
        .setSort(ApplicantSort.matchScore);
    expect(c.read(filteredApplicantsProvider).map((a) => a.id), ['a', 'b', 'c']);
  });

  test('job scope restricts to one job', () async {
    final c = await _seeded();
    c.read(employerApplicantsFilterProvider.notifier).setJob('j2');
    expect(c.read(filteredApplicantsProvider).map((a) => a.id), ['c']);
    expect(c.read(applicantsForJobProvider('j1')).map((a) => a.id), ['b', 'a']);
  });

  test('stats count per status', () async {
    final c = await _seeded();
    final stats = c.read(employerApplicantsStatsProvider);
    expect(stats.total, 3);
    expect(stats.pending, 1);
    expect(stats.interview, 1);
    expect(stats.accepted, 1);
  });
}
