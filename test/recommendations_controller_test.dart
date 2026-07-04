import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/ai/ai_exception.dart';
import 'package:careerbridge/core/services/jobs/jobs_repository.dart';
import 'package:careerbridge/core/services/jobs/seed_jobs_repository.dart';
import 'package:careerbridge/core/services/recommendations_store/in_memory_recommendations_store.dart';
import 'package:careerbridge/core/services/recommendations_store/recommendations_store.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/features/recommendations/application/recommendations_controller.dart';
import 'package:careerbridge/features/recommendations/data/recommendations_repository_impl.dart';
import 'package:careerbridge/features/recommendations/domain/recommendation_context.dart';
import 'package:careerbridge/features/recommendations/domain/recommendation_models.dart';
import 'package:careerbridge/features/recommendations/domain/recommendations_repository.dart';
import 'package:careerbridge/shared/models/job.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth.dart';

class FakeRecommendationsRepository implements RecommendationsRepository {
  FakeRecommendationsRepository({this.error, this.result});
  final Object? error;
  final Recommendations? result;
  int calls = 0;

  @override
  Future<Recommendations> generate({
    required RecommendationContext context,
    required String languageCode,
  }) async {
    calls++;
    if (error != null) throw error!;
    return result ??
        const Recommendations(
          headline: 'Hi',
          skillsToLearn: [SkillRecommendation(skill: 'Dart', reason: 'r')],
        );
  }
}

class FakeJobsRepository implements JobsRepository {
  @override
  Future<List<Job>> fetchJobs() async => const [];
  @override
  Future<Job?> fetchJobById(String id) async => null;
  @override
  Future<List<Job>> searchJobs(JobQuery query) async => const [];
}

Future<void> _settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<ProviderContainer> _container({
  FakeRecommendationsRepository? repo,
  RecommendationsStore? store,
  DateTime Function()? clock,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorageService.create();
  final overrides = <Override>[
    fakeAuthOverride(),
    localStorageProvider.overrideWithValue(storage),
    jobsRepositoryProvider.overrideWithValue(FakeJobsRepository()),
    recommendationsRepositoryProvider
        .overrideWithValue(repo ?? FakeRecommendationsRepository()),
    if (store != null)
      recommendationsStoreProvider.overrideWithValue(store),
    if (clock != null)
      recommendationsControllerProvider.overrideWith(
          (ref) => RecommendationsController(ref, clock: clock)),
  ];
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('cold start generates, becomes ready, and caches the result', () async {
    final repo = FakeRecommendationsRepository();
    final c = await _container(repo: repo);
    c.read(recommendationsControllerProvider); // trigger construction
    await _settle();

    final state = c.read(recommendationsControllerProvider);
    expect(state.phase, RecommendationsPhase.ready);
    expect(state.recommendations?.headline, 'Hi');
    expect(repo.calls, 1);
    expect(c.read(recommendationsStoreProvider).read(), isNotNull);
  });

  test('a cached result hydrates without an AI call', () async {
    const seeded = Recommendations(
        headline: 'cached', skillsToLearn: [SkillRecommendation(skill: 'x')]);
    final repo = FakeRecommendationsRepository();
    final c = await _container(
        repo: repo, store: InMemoryRecommendationsStore(seed: seeded));
    c.read(recommendationsControllerProvider);
    await _settle();

    final state = c.read(recommendationsControllerProvider);
    expect(state.phase, RecommendationsPhase.ready);
    expect(state.recommendations?.headline, 'cached');
    expect(repo.calls, 0);
  });

  test('refresh skips the AI call when the source data is unchanged', () async {
    final repo = FakeRecommendationsRepository();
    final c = await _container(repo: repo);
    final ctrl = c.read(recommendationsControllerProvider.notifier);
    await _settle(); // cold generate
    expect(repo.calls, 1);

    await ctrl.refresh();
    await _settle();

    expect(repo.calls, 1); // unchanged -> skipped
    expect(c.read(recommendationsControllerProvider).upToDate, isTrue);
  });

  test('a generation failure with no cache maps to an error phase', () async {
    final c = await _container(
        repo: FakeRecommendationsRepository(
            error: const AiException(AiErrorCode.network)));
    c.read(recommendationsControllerProvider);
    await _settle();

    final state = c.read(recommendationsControllerProvider);
    expect(state.phase, RecommendationsPhase.error);
    expect(state.failure, RecommendationFailure.network);
  });

  test('generatedAt is stamped from the injected clock', () async {
    final c = await _container(clock: () => DateTime(2026, 7, 4, 9));
    c.read(recommendationsControllerProvider);
    await _settle();

    expect(c.read(recommendationsControllerProvider).recommendations?.generatedAt,
        DateTime(2026, 7, 4, 9));
  });
}
