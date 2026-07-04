import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/applications/in_memory_applications_repository.dart';
import 'package:careerbridge/core/services/jobs/jobs_repository.dart';
import 'package:careerbridge/core/services/jobs/seed_jobs_repository.dart';
import 'package:careerbridge/core/services/recommendations_store/in_memory_recommendations_store.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/features/recommendations/application/recommendations_controller.dart';
import 'package:careerbridge/features/recommendations/domain/recommendation_models.dart';
import 'package:careerbridge/shared/models/job.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth.dart';

class StaticJobsRepository implements JobsRepository {
  StaticJobsRepository(this.jobs);
  final List<Job> jobs;
  @override
  Future<List<Job>> fetchJobs() async => jobs;
  @override
  Future<Job?> fetchJobById(String id) async {
    for (final j in jobs) {
      if (j.id == id) return j;
    }
    return null;
  }
  @override
  Future<List<Job>> searchJobs(JobQuery query) async => jobs;
}

Job _job(String id, String title, {List<String> skills = const []}) => Job(
      id: id,
      title: title,
      company: 'Co-$id',
      location: '',
      employmentType: 'Full-time',
      seniority: 'Mid',
      description: '',
      requiredSkills: skills,
      remote: false,
    );

void main() {
  test('buildContext flattens applications + jobs and excludes applied', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorageService.create();

    final job1 = _job('j1', 'Flutter Dev', skills: ['Flutter']);
    final job2 = _job('j2', 'iOS Dev', skills: ['Swift']);

    final appsRepo = InMemoryApplicationsRepository(clock: () => DateTime(2026, 7, 4));
    await appsRepo.apply(job: job2);

    final container = ProviderContainer(overrides: [
      fakeAuthOverride(),
      localStorageProvider.overrideWithValue(storage),
      applicationsRepositoryProvider.overrideWithValue(appsRepo),
      jobsRepositoryProvider.overrideWithValue(StaticJobsRepository([job1, job2])),
      // Seed the store so the controller does NOT auto-generate.
      recommendationsStoreProvider.overrideWithValue(
        InMemoryRecommendationsStore(
          seed: const Recommendations(
              headline: 'x', skillsToLearn: [SkillRecommendation(skill: 'y')]),
        ),
      ),
    ]);
    addTearDown(container.dispose);

    final ctrl = container.read(recommendationsControllerProvider.notifier);
    final ctx = await ctrl.buildContext();

    expect(ctx.availableJobs.length, 2);
    expect(ctx.appliedJobIds, {'j2'});
    expect(ctx.appliedCount, 1);
    expect(ctx.appliedTitles, contains('iOS Dev'));
    expect(ctx.hasSignal, isTrue); // has application activity

    // Signature is deterministic across identical builds.
    final sig = ctx.signature;
    expect(sig, isNotEmpty);
    expect((await ctrl.buildContext()).signature, sig);
  });
}
