import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/services/activity/employer_activity_repository.dart';
import 'package:careerbridge/core/services/activity/in_memory_employer_activity_repository.dart';
import 'package:careerbridge/core/services/applications/employer_applicants_repository.dart';
import 'package:careerbridge/core/services/applications/in_memory_employer_applicants_repository.dart';
import 'package:careerbridge/core/services/jobs/employer_jobs_repository.dart';
import 'package:careerbridge/core/services/jobs/in_memory_employer_jobs_repository.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/theme/app_theme.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/employer/application/employer_analytics_providers.dart';
import 'package:careerbridge/features/employer/application/recruiter_insights_controller.dart';
import 'package:careerbridge/features/employer/domain/analytics/recruiter_insights.dart';
import 'package:careerbridge/features/employer/domain/job_status.dart';
import 'package:careerbridge/features/employer/presentation/employer_analytics_screen.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/applicant_snapshot.dart';
import 'package:careerbridge/shared/models/application.dart';
import 'package:careerbridge/shared/models/job_posting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'support/fake_auth.dart';

const _user = AppUser(uid: 'emp1', method: AuthMethod.email, email: 'e@b.co');
final _now = DateTime(2026, 7, 15, 12);

JobPosting _job(String id, JobStatus status) =>
    JobPosting(id: id, companyId: 'emp1', ownerUid: 'emp1', title: 'Job $id', status: status);

Application _app(String id, ApplicationStatus status, int match) => Application(
      id: id,
      jobId: 'j1',
      jobTitle: 'Flutter Engineer',
      company: 'Acme',
      location: 'Doha',
      status: status,
      appliedAt: DateTime(2026, 7, 13),
      updatedAt: DateTime(2026, 7, 14),
      history: [
        ApplicationEvent(status: ApplicationStatus.pending, at: DateTime(2026, 7, 13)),
        if (status != ApplicationStatus.pending)
          ApplicationEvent(status: status, at: DateTime(2026, 7, 14)),
      ],
      ownerUid: 'emp1',
      applicant: ApplicantSnapshot(
        name: 'A $id',
        skills: const ['Flutter', 'Dart'],
        atsScore: 82,
        matchScore: match,
      ),
    );

Widget _host(Locale locale, {List<Override> extra = const []}) => ProviderScope(
      overrides: [
        authRepositoryProvider
            .overrideWithValue(FakeAuthRepository(user: _user)),
        analyticsClockProvider.overrideWithValue(() => _now),
        employerJobsRepositoryProvider.overrideWithValue(
            InMemoryEmployerJobsRepository(seed: [_job('j1', JobStatus.published)])),
        employerApplicantsRepositoryProvider.overrideWithValue(
          InMemoryEmployerApplicantsRepository(seed: [
            _app('a', ApplicationStatus.pending, 90),
            _app('b', ApplicationStatus.interview, 55),
          ]),
        ),
        employerActivityRepositoryProvider
            .overrideWithValue(InMemoryEmployerActivityRepository()),
        ...extra,
      ],
      child: MaterialApp(
        locale: locale,
        theme: AppTheme.light(locale),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: supportedLocales,
        home: const EmployerAnalyticsScreen(),
      ),
    );

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();
    final expectedDir =
        locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    testWidgets('Analytics dashboard renders in $tag with no overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 2800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(locale));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Analytics ($tag) threw');
      final dir = Directionality.of(
          tester.element(find.byType(EmployerAnalyticsScreen)));
      expect(dir, expectedDir);
    });

    testWidgets('Insights ready state renders in $tag', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 2800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(locale, extra: [
        recruiterInsightsControllerProvider.overrideWith(
          (ref) => RecruiterInsightsController.seeded(
            ref,
            const RecruiterInsightsState(
              phase: RecruiterInsightsPhase.ready,
              insights: RecruiterInsights(
                headline: 'Solid pipeline',
                summary: 'Focus on interviews.',
                strengths: [InsightItem(title: 'Good match', detail: 'd')],
                bottlenecks: [InsightItem(title: 'Slow review', detail: 'd')],
                suggestedActions: [
                  InsightAction(
                      title: 'Act', detail: 'd', priority: InsightPriority.high)
                ],
              ),
            ),
          ),
        ),
      ]));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Solid pipeline'), findsOneWidget);
    });
  }

  testWidgets('Overview + funnel titles render (EN)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 2800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host(const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Application funnel'), findsOneWidget);
    expect(find.text('AI recruiter insights'), findsOneWidget);
    // Idle insights card offers to generate.
    expect(find.text('Generate insights'), findsOneWidget);
  });
}
