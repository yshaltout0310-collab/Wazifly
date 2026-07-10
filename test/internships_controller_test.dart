import 'package:careerbridge/core/services/jobs/jobs_repository.dart';
import 'package:careerbridge/core/services/jobs/seed_jobs_repository.dart';
import 'package:careerbridge/features/internships/application/internships_controller.dart';
import 'package:careerbridge/shared/models/internship_details.dart';
import 'package:careerbridge/shared/models/job.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fixed-list jobs source: two internships + one full-time role.
class _FakeJobs implements JobsRepository {
  @override
  Future<List<Job>> fetchJobs() async => const [
        Job(
          id: 'ft',
          title: 'Engineer',
          company: 'Acme',
          location: 'Doha',
          employmentType: 'Full-time',
          seniority: 'Mid',
          description: 'x',
          requiredSkills: ['Dart'],
          remote: false,
        ),
        Job(
          id: 'int-paid-sw',
          title: 'Flutter Intern',
          company: 'Northwind',
          location: 'Doha',
          employmentType: 'Internship',
          seniority: 'Entry',
          description: 'x',
          requiredSkills: ['Flutter'],
          remote: true,
          internship: InternshipDetails(
            funding: InternshipFunding.paid,
            category: InternshipCategory.software,
            workMode: WorkMode.remote,
          ),
        ),
        Job(
          id: 'int-unpaid-data',
          title: 'Data Intern',
          company: 'Cedar',
          location: 'Remote',
          employmentType: 'Internship',
          seniority: 'Entry',
          description: 'x',
          requiredSkills: ['SQL'],
          remote: true,
          internship: InternshipDetails(
            funding: InternshipFunding.unpaid,
            category: InternshipCategory.data,
            workMode: WorkMode.onsite,
          ),
        ),
      ];

  @override
  Future<Job?> fetchJobById(String id) async => null;
  @override
  Future<List<Job>> searchJobs(JobQuery query) async => fetchJobs();
}

void main() {
  late ProviderContainer c;

  Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 10));

  setUp(() {
    c = ProviderContainer(overrides: [
      jobsRepositoryProvider.overrideWithValue(_FakeJobs()),
    ]);
    // Instantiate the controller eagerly so its async `_load()` starts before
    // the per-test `pump()`.
    c.listen(internshipsControllerProvider, (_, __) {});
    addTearDown(c.dispose);
  });

  InternshipsController ctrl() =>
      c.read(internshipsControllerProvider.notifier);
  InternshipsState state() => c.read(internshipsControllerProvider);

  test('load keeps only internships', () async {
    await pump();
    expect(state().status, InternshipsStatus.ready);
    expect(state().all.length, 2);
    expect(state().all.every((j) => j.isInternship), true);
  });

  test('funding facet filters', () async {
    await pump();
    ctrl().toggleFunding(InternshipFunding.paid);
    expect(state().results.map((j) => j.id), ['int-paid-sw']);
    ctrl().toggleFunding(InternshipFunding.paid); // clear
    expect(state().results.length, 2);
  });

  test('category facet filters', () async {
    await pump();
    ctrl().toggleCategory(InternshipCategory.data);
    expect(state().results.single.id, 'int-unpaid-data');
  });

  test('work-mode facet filters', () async {
    await pump();
    ctrl().toggleWorkMode(WorkMode.remote);
    expect(state().results.single.id, 'int-paid-sw');
  });

  test('text search matches title/company/skills', () async {
    await pump();
    ctrl().updateText('sql');
    expect(state().results.single.id, 'int-unpaid-data');
    ctrl().updateText('');
    expect(state().results.length, 2);
  });

  test('clearFilters keeps text but drops facets', () async {
    await pump();
    ctrl().updateText('intern');
    ctrl().toggleFunding(InternshipFunding.paid);
    ctrl().clearFilters();
    expect(state().filter.text, 'intern');
    expect(state().filter.hasFacetFilters, false);
  });
}
