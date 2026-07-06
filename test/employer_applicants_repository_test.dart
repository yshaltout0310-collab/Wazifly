import 'package:careerbridge/core/services/applications/in_memory_employer_applicants_repository.dart';
import 'package:careerbridge/shared/models/application.dart';
import 'package:flutter_test/flutter_test.dart';

Application _app(String id,
        {String owner = 'emp1',
        ApplicationStatus status = ApplicationStatus.pending,
        DateTime? updated}) =>
    Application(
      id: id,
      jobId: 'job1',
      jobTitle: 'Flutter Engineer',
      company: 'Acme',
      location: 'Doha',
      status: status,
      appliedAt: DateTime(2026, 7, 1),
      updatedAt: updated ?? DateTime(2026, 7, 1),
      history: const [],
      applicantUid: 'seeker_$id',
      ownerUid: owner,
    );

void main() {
  test('watchApplicants returns only the owner, newest-updated first', () async {
    final repo = InMemoryEmployerApplicantsRepository(seed: [
      _app('a', updated: DateTime(2026, 7, 1)),
      _app('b', updated: DateTime(2026, 7, 5)),
      _app('c', owner: 'other', updated: DateTime(2026, 7, 9)),
    ]);
    final first = await repo.watchApplicants('emp1').first;
    expect(first.map((a) => a.id), ['b', 'a']);
  });

  test('updateApplication re-emits and persists', () async {
    final repo = InMemoryEmployerApplicantsRepository(seed: [_app('a')]);
    final emissions = <List<String>>[];
    final sub = repo
        .watchApplicants('emp1')
        .listen((apps) => emissions.add(apps.map((a) => a.id).toList()));

    final updated = _app('a', status: ApplicationStatus.interview)
        .withStatus(ApplicationStatus.interview, DateTime(2026, 7, 6));
    await repo.updateApplication(updated);
    await Future<void>.delayed(Duration.zero);

    expect(emissions.last, ['a']);
    expect((await repo.fetchApplicant('a'))?.status,
        ApplicationStatus.interview);
    await sub.cancel();
  });

  test('fetchApplicant returns null for missing id', () async {
    final repo = InMemoryEmployerApplicantsRepository(seed: [_app('a')]);
    expect(await repo.fetchApplicant('a'), isNotNull);
    expect(await repo.fetchApplicant('missing'), isNull);
  });
}
