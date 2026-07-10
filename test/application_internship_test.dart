import 'package:careerbridge/core/services/applications/in_memory_applications_repository.dart';
import 'package:careerbridge/features/applications/application/applications_controller.dart';
import 'package:careerbridge/shared/models/internship_details.dart';
import 'package:careerbridge/shared/models/job.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const normalJob = Job(
    id: 'ft',
    title: 'Engineer',
    company: 'Acme',
    location: 'Doha',
    employmentType: 'Full-time',
    seniority: 'Mid',
    description: 'x',
    requiredSkills: [],
    remote: false,
  );

  const internJob = Job(
    id: 'int',
    title: 'Intern',
    company: 'Northwind',
    location: 'Doha',
    employmentType: 'Internship',
    seniority: 'Entry',
    description: 'x',
    requiredSkills: [],
    remote: true,
    internship: InternshipDetails(funding: InternshipFunding.paid),
  );

  test('apply stamps isInternship from the job', () async {
    final repo = InMemoryApplicationsRepository();
    final a = await repo.apply(job: internJob);
    final b = await repo.apply(job: normalJob);
    expect(a.isInternship, true);
    expect(b.isInternship, false);
  });

  test('isInternship survives JSON round-trip', () async {
    final repo = InMemoryApplicationsRepository();
    final a = await repo.apply(job: internJob);
    expect(a.toJson()['isInternship'], true);
    expect(normalJob.isInternship, false);
  });

  test('filteredApplicationsProvider internshipsOnly narrows the list',
      () async {
    final repo = InMemoryApplicationsRepository();
    await repo.apply(job: internJob);
    await repo.apply(job: normalJob);

    final c = ProviderContainer(overrides: [
      applicationsRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);
    c.listen(applicationsProvider, (_, __) {});
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(c.read(filteredApplicationsProvider).length, 2);

    c.read(applicationsFilterProvider.notifier).toggleInternshipsOnly();
    final only = c.read(filteredApplicationsProvider);
    expect(only.length, 1);
    expect(only.single.jobId, 'int');
  });
}
