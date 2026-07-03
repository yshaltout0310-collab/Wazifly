import 'package:careerbridge/core/services/applications/in_memory_applications_repository.dart';
import 'package:careerbridge/shared/models/application.dart';
import 'package:careerbridge/shared/models/job.dart';
import 'package:flutter_test/flutter_test.dart';

Job _job(String id) => Job(
      id: id,
      title: 'Job $id',
      company: 'Acme',
      location: 'Doha',
      employmentType: 'Full-time',
      seniority: 'Mid',
      description: 'x',
      requiredSkills: const ['Flutter'],
      remote: false,
    );

void main() {
  late DateTime now;
  late InMemoryApplicationsRepository repo;

  setUp(() {
    now = DateTime(2026, 1, 10, 9);
    repo = InMemoryApplicationsRepository(clock: () => now);
  });

  test('apply creates a Pending application', () async {
    final app = await repo.apply(job: _job('j1'));
    expect(app.status, ApplicationStatus.pending);
    expect(app.jobId, 'j1');
    expect(app.appliedAt, now);
    expect(await repo.findByJobId('j1'), isNotNull);
  });

  test('apply is idempotent per jobId', () async {
    final a = await repo.apply(job: _job('j1'));
    final b = await repo.apply(job: _job('j1'));
    expect(a.id, b.id);
    final all = await repo.watchApplications().first;
    expect(all.length, 1);
  });

  test('updateStatus appends history and bumps updatedAt', () async {
    final a = await repo.apply(job: _job('j1'));
    now = DateTime(2026, 1, 12, 10);
    await repo.updateStatus(a.id, ApplicationStatus.interview);

    final updated = await repo.findByJobId('j1');
    expect(updated!.status, ApplicationStatus.interview);
    expect(updated.updatedAt, DateTime(2026, 1, 12, 10));
    expect(updated.history.map((e) => e.status),
        [ApplicationStatus.pending, ApplicationStatus.interview]);
  });

  test('withdraw removes the application', () async {
    final a = await repo.apply(job: _job('j1'));
    await repo.withdraw(a.id);
    expect(await repo.findByJobId('j1'), isNull);
    expect(await repo.watchApplications().first, isEmpty);
  });

  test('watchApplications emits current value then updates', () async {
    final emissions = <List<Application>>[];
    final sub = repo.watchApplications().listen(emissions.add);
    await Future<void>.delayed(Duration.zero);

    await repo.apply(job: _job('j1'));
    await repo.apply(job: _job('j2'));
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    // First emission is the initial (empty) snapshot; last has both jobs.
    expect(emissions.first, isEmpty);
    expect(emissions.last.map((a) => a.jobId), containsAll(['j1', 'j2']));
  });
}
