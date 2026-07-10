import 'package:careerbridge/core/services/applications/in_memory_applications_repository.dart';
import 'package:careerbridge/shared/models/job.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const job = Job(
    id: 'j1',
    title: 'Engineer',
    company: 'Acme',
    location: 'Remote',
    employmentType: 'Full-time',
    seniority: 'Mid',
    description: 'x',
    requiredSkills: [],
    remote: true,
  );

  test('apply records the chosen CV id + name', () async {
    final repo = InMemoryApplicationsRepository();
    final app = await repo.apply(job: job, cvId: 'cv-1', cvName: 'Backend CV');
    expect(app.cvId, 'cv-1');
    expect(app.cvName, 'Backend CV');
  });

  test('apply without a CV keeps the fields empty (no regression)', () async {
    final repo = InMemoryApplicationsRepository();
    final app = await repo.apply(job: job);
    expect(app.cvId, '');
    expect(app.cvName, '');
  });

  test('cvId/cvName survive JSON round-trip', () async {
    final repo = InMemoryApplicationsRepository();
    final app = await repo.apply(job: job, cvId: 'cv-9', cvName: 'AI CV');
    final back = app.toJson();
    expect(back['cvId'], 'cv-9');
    expect(back['cvName'], 'AI CV');
  });
}
