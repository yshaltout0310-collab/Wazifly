import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/ai/ai_exception.dart';
import 'package:careerbridge/core/services/recruiter_insights_store/in_memory_recruiter_insights_store.dart';
import 'package:careerbridge/core/services/recruiter_insights_store/recruiter_insights_store.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/features/employer/application/company_providers.dart';
import 'package:careerbridge/features/employer/application/employer_analytics_providers.dart';
import 'package:careerbridge/features/employer/application/recruiter_insights_controller.dart';
import 'package:careerbridge/features/employer/data/recruiter_insights_repository_impl.dart';
import 'package:careerbridge/features/employer/domain/analytics/employer_analytics.dart';
import 'package:careerbridge/features/employer/domain/analytics/recruiter_insights.dart';
import 'package:careerbridge/features/employer/domain/analytics/recruiter_insights_context.dart';
import 'package:careerbridge/features/employer/domain/analytics/recruiter_insights_exception.dart';
import 'package:careerbridge/features/employer/domain/analytics/recruiter_insights_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth.dart';

class FakeRecruiterInsightsRepository implements RecruiterInsightsRepository {
  FakeRecruiterInsightsRepository({this.error, this.result});
  final Object? error;
  final RecruiterInsights? result;
  int calls = 0;

  @override
  Future<RecruiterInsights> generate({
    required RecruiterInsightsContext context,
    required String languageCode,
  }) async {
    calls++;
    if (error != null) throw error!;
    return result ??
        const RecruiterInsights(
          headline: 'Insights',
          summary: 's',
          strengths: [InsightItem(title: 'Good', detail: 'd')],
        );
  }
}

// Analytics with applicants (so generation is possible).
const _analytics = EmployerAnalytics(
  overview: OverviewKpis(totalJobs: 2, activeJobs: 1, totalApplicants: 5, hires: 1),
);

Future<ProviderContainer> _container({
  FakeRecruiterInsightsRepository? repo,
  RecruiterInsightsStore? store,
  DateTime Function()? clock,
  EmployerAnalytics analytics = _analytics,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorageService.create();
  final overrides = <Override>[
    fakeAuthOverride(),
    localStorageProvider.overrideWithValue(storage),
    currentCompanyProvider.overrideWithValue(null),
    employerAnalyticsProvider.overrideWithValue(analytics),
    recruiterInsightsRepositoryProvider
        .overrideWithValue(repo ?? FakeRecruiterInsightsRepository()),
    if (store != null)
      recruiterInsightsStoreProvider.overrideWithValue(store),
    if (clock != null)
      recruiterInsightsControllerProvider.overrideWith(
          (ref) => RecruiterInsightsController(ref, clock: clock)),
  ];
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('starts idle without an AI call', () async {
    final repo = FakeRecruiterInsightsRepository();
    final c = await _container(repo: repo);
    final state = c.read(recruiterInsightsControllerProvider);
    expect(state.phase, RecruiterInsightsPhase.idle);
    expect(state.insights, isNull);
    expect(repo.calls, 0);
  });

  test('generate produces ready state and caches the result', () async {
    final repo = FakeRecruiterInsightsRepository();
    final c = await _container(repo: repo);
    await c.read(recruiterInsightsControllerProvider.notifier).generate();

    final state = c.read(recruiterInsightsControllerProvider);
    expect(state.phase, RecruiterInsightsPhase.ready);
    expect(state.insights?.headline, 'Insights');
    expect(repo.calls, 1);
    expect(c.read(recruiterInsightsStoreProvider).read(), isNotNull);
  });

  test('a cached result hydrates without an AI call', () async {
    const seeded = RecruiterInsights(headline: 'cached', summary: 'x');
    final repo = FakeRecruiterInsightsRepository();
    final c = await _container(
        repo: repo, store: InMemoryRecruiterInsightsStore(seed: seeded));
    final state = c.read(recruiterInsightsControllerProvider);
    expect(state.phase, RecruiterInsightsPhase.ready);
    expect(state.insights?.headline, 'cached');
    expect(repo.calls, 0);
  });

  test('refresh skips the AI call when analytics are unchanged', () async {
    final repo = FakeRecruiterInsightsRepository();
    final c = await _container(repo: repo);
    final ctrl = c.read(recruiterInsightsControllerProvider.notifier);
    await ctrl.generate();
    expect(repo.calls, 1);

    await ctrl.refresh();
    expect(repo.calls, 1); // unchanged -> skipped
    expect(c.read(recruiterInsightsControllerProvider).upToDate, isTrue);
  });

  test('a generation failure with no cache maps to an error phase', () async {
    final c = await _container(
        repo: FakeRecruiterInsightsRepository(
            error: const AiException(AiErrorCode.network)));
    await c.read(recruiterInsightsControllerProvider.notifier).generate();

    final state = c.read(recruiterInsightsControllerProvider);
    expect(state.phase, RecruiterInsightsPhase.error);
    expect(state.failure, RecruiterInsightsFailure.network);
  });

  test('empty-insights failure maps to the empty category', () async {
    final c = await _container(
        repo: FakeRecruiterInsightsRepository(
            error: const RecruiterInsightsException(
                RecruiterInsightsErrorCode.emptyInsights)));
    await c.read(recruiterInsightsControllerProvider.notifier).generate();
    expect(c.read(recruiterInsightsControllerProvider).failure,
        RecruiterInsightsFailure.empty);
  });

  test('generatedAt is stamped from the injected clock', () async {
    final c = await _container(clock: () => DateTime(2026, 7, 4, 9));
    await c.read(recruiterInsightsControllerProvider.notifier).generate();
    expect(c.read(recruiterInsightsControllerProvider).insights?.generatedAt,
        DateTime(2026, 7, 4, 9));
  });
}
