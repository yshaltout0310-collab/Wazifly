import 'package:careerbridge/core/services/activity/employer_activity_repository.dart';
import 'package:careerbridge/core/services/activity/in_memory_employer_activity_repository.dart';
import 'package:careerbridge/core/services/applications/employer_applicants_repository.dart';
import 'package:careerbridge/core/services/applications/in_memory_employer_applicants_repository.dart';
import 'package:careerbridge/core/services/jobs/employer_jobs_repository.dart';
import 'package:careerbridge/core/services/jobs/in_memory_employer_jobs_repository.dart';
import 'package:careerbridge/features/employer/application/employer_analytics_providers.dart';
import 'package:careerbridge/features/employer/application/recruiter_insights_controller.dart';
import 'package:careerbridge/features/employer/domain/analytics/analytics_calculator.dart';
import 'package:careerbridge/features/employer/domain/analytics/employer_analytics.dart';
import 'package:careerbridge/features/employer/domain/job_status.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/applicant_snapshot.dart';
import 'package:careerbridge/shared/models/application.dart';
import 'package:careerbridge/shared/models/job_posting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

const _user = AppUser(uid: 'c', method: AuthMethod.email, email: 'e@c.co');
final _now = DateTime(2026, 7, 15, 12);

JobPosting _job(String id, JobStatus status) =>
    JobPosting(id: id, companyId: 'c', ownerUid: 'c', title: 'Job $id', status: status);

Application _app(String id, String jobId, ApplicationStatus status,
        {int? match, List<String> skills = const []}) =>
    Application(
      id: id,
      jobId: jobId,
      jobTitle: 'Job $jobId',
      company: 'Acme',
      location: 'Doha',
      status: status,
      appliedAt: DateTime(2026, 7, 14),
      updatedAt: DateTime(2026, 7, 14),
      history: [
        ApplicationEvent(status: ApplicationStatus.pending, at: DateTime(2026, 7, 14)),
        if (status != ApplicationStatus.pending)
          ApplicationEvent(status: status, at: DateTime(2026, 7, 14)),
      ],
      ownerUid: 'c',
      applicant: ApplicantSnapshot(name: 'A $id', matchScore: match, skills: skills),
    );

Future<void> _settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

ProviderContainer _container({
  List<JobPosting> jobs = const [],
  List<Application> apps = const [],
}) {
  final container = ProviderContainer(overrides: [
    fakeAuthOverride(user: _user),
    analyticsClockProvider.overrideWithValue(() => _now),
    employerJobsRepositoryProvider
        .overrideWithValue(InMemoryEmployerJobsRepository(seed: jobs)),
    employerApplicantsRepositoryProvider
        .overrideWithValue(InMemoryEmployerApplicantsRepository(seed: apps)),
    employerActivityRepositoryProvider
        .overrideWithValue(InMemoryEmployerActivityRepository()),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('employerAnalyticsProvider computes from the employer streams', () async {
    final c = _container(
      jobs: [_job('j1', JobStatus.published), _job('j2', JobStatus.draft)],
      apps: [
        _app('1', 'j1', ApplicationStatus.pending, match: 90),
        _app('2', 'j1', ApplicationStatus.interview, match: 70),
      ],
    );
    // Keep the streams alive so they resolve.
    final sub = c.listen(employerAnalyticsProvider, (_, __) {});
    addTearDown(sub.close);
    await _settle();

    final a = c.read(employerAnalyticsProvider);
    expect(a.overview.totalJobs, 2);
    expect(a.overview.activeJobs, 1);
    expect(a.overview.totalApplicants, 2);
    expect(a.funnel.interview, 1);
    expect(a.overview.avgMatchScore, 80);
  });

  test('provider yields empty analytics when signed out', () async {
    final container = ProviderContainer(overrides: [
      fakeAuthOverride(), // no user
      analyticsClockProvider.overrideWithValue(() => _now),
      employerJobsRepositoryProvider
          .overrideWithValue(InMemoryEmployerJobsRepository()),
      employerApplicantsRepositoryProvider
          .overrideWithValue(InMemoryEmployerApplicantsRepository()),
      employerActivityRepositoryProvider
          .overrideWithValue(InMemoryEmployerActivityRepository()),
    ]);
    addTearDown(container.dispose);
    final sub = container.listen(employerAnalyticsProvider, (_, __) {});
    addTearDown(sub.close);
    await _settle();

    expect(container.read(employerAnalyticsProvider).hasApplicants, isFalse);
  });

  group('contextFromAnalytics', () {
    test('flattens computed analytics into the prompt context', () {
      final analytics = AnalyticsCalculator.compute(
        jobs: [_job('j1', JobStatus.published)],
        applicants: [
          _app('1', 'j1', ApplicationStatus.interview, match: 90, skills: ['Flutter']),
          _app('2', 'j1', ApplicationStatus.pending, match: 30, skills: ['Flutter', 'Go']),
        ],
        now: _now,
      );
      final ctx = contextFromAnalytics(analytics, companyName: 'Acme');
      expect(ctx.companyName, 'Acme');
      expect(ctx.totalApplicants, 2);
      expect(ctx.interview, 1);
      expect(ctx.strongMatchCount, 1); // score 90
      expect(ctx.weakMatchCount, 1); // score 30
      expect(ctx.topJobs.single.title, 'Job j1');
      expect(ctx.topSkills, contains('Flutter'));
      expect(ctx.hasData, isTrue);
      expect(ctx.signature, isNotEmpty);
    });

    test('signature is stable across equal analytics and empty when no data', () {
      final empty = contextFromAnalytics(EmployerAnalytics.empty);
      expect(empty.hasData, isFalse);

      final a1 = AnalyticsCalculator.compute(
          jobs: const [], applicants: apps0(), now: _now);
      final a2 = AnalyticsCalculator.compute(
          jobs: const [], applicants: apps0(), now: _now);
      expect(contextFromAnalytics(a1).signature,
          contextFromAnalytics(a2).signature);
    });
  });
}

// Helper to keep the two-arg call above readable.
List<Application> apps0() => [
      _app('1', 'j1', ApplicationStatus.pending, match: 50),
    ];
