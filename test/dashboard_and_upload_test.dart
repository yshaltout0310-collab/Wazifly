import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/navigation/route_names.dart';
import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/applications/employer_applicants_repository.dart';
import 'package:careerbridge/core/services/applications/in_memory_employer_applicants_repository.dart';
import 'package:careerbridge/core/services/company/company_repository.dart';
import 'package:careerbridge/core/services/company/in_memory_company_repository.dart';
import 'package:careerbridge/core/services/jobs/employer_jobs_repository.dart';
import 'package:careerbridge/core/services/jobs/in_memory_employer_jobs_repository.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/core/theme/app_theme.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/employer/application/employer_applicants_providers.dart';
import 'package:careerbridge/features/employer/application/employer_jobs_providers.dart';
import 'package:careerbridge/features/employer/domain/employment_type.dart';
import 'package:careerbridge/features/employer/domain/job_experience.dart';
import 'package:careerbridge/features/employer/domain/job_status.dart';
import 'package:careerbridge/features/employer/presentation/employer_home_screen.dart';
import 'package:careerbridge/features/home/presentation/home_screen.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/application.dart';
import 'package:careerbridge/shared/models/company.dart';
import 'package:careerbridge/shared/models/job_posting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth.dart';

/// Discoverability and dashboard actions.
///
/// * The four employer stat tiles were plain `Container`s — no `InkWell`, no
///   `onTap` — sitting beside cards that *were* tappable, which is why they
///   read as broken rather than as labels.
/// * Uploading a CV already worked, but every surface was named after the AI
///   feature that used it ("Resume Analyzer", "CV Builder", "My CVs"), so the
///   capability read as missing.

const _user = AppUser(uid: 'c1', method: AuthMethod.email, email: 'a@b.co');

late LocalStorageService _storage;

JobPosting _job(String id, JobStatus status) => JobPosting(
      id: id,
      companyId: 'c1',
      ownerUid: 'c1',
      companyName: 'Acme',
      title: 'Role $id',
      description: 'A perfectly adequate description of the role on offer.',
      requiredSkills: const ['Flutter'],
      location: 'Doha',
      employmentType: EmploymentType.fullTime,
      experience: JobExperience.senior,
      status: status,
      updatedAt: DateTime(2026, 7, 1),
    );

Application _application(String id, ApplicationStatus status) => Application(
      id: id,
      jobId: 'j1',
      jobTitle: 'Role j1',
      company: 'Acme',
      location: 'Doha',
      ownerUid: 'c1',
      companyId: 'c1',
      applicantUid: 'seeker_$id',
      status: status,
      appliedAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
      history: const [],
    );

GoRoute _stub(String path, String name, String marker) => GoRoute(
      path: path,
      name: name,
      builder: (_, __) => Scaffold(body: Center(child: Text(marker))),
    );

Widget _employerApp({
  required List<JobPosting> jobs,
  required List<Application> applications,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const EmployerHomeScreen()),
      _stub('/jobs', RouteNames.employerJobs, 'MY JOBS'),
      _stub('/applicants', RouteNames.employerApplicants, 'APPLICANTS'),
      _stub('/analytics', RouteNames.employerAnalytics, 'ANALYTICS'),
      _stub('/company', RouteNames.companyProfile, 'COMPANY'),
      _stub('/settings', RouteNames.settings, 'SETTINGS'),
    ],
  );

  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(_storage),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository(user: _user)),
      companyRepositoryProvider.overrideWithValue(InMemoryCompanyRepository(
          seed: [Company.empty('c1').copyWith(name: 'Acme')])),
      employerJobsRepositoryProvider
          .overrideWithValue(InMemoryEmployerJobsRepository(seed: jobs)),
      employerApplicantsRepositoryProvider.overrideWithValue(
          InMemoryEmployerApplicantsRepository(seed: applications)),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      theme: AppTheme.light(const Locale('en')),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _storage = await LocalStorageService.create();
  });

  group('employer dashboard stat cards', () {
    Future<ProviderContainer> pump(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_employerApp(
        jobs: [_job('j1', JobStatus.published), _job('j2', JobStatus.draft)],
        applications: [
          _application('a1', ApplicationStatus.interview),
          _application('a2', ApplicationStatus.accepted),
        ],
      ));
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
        tester.element(find.byType(EmployerHomeScreen)),
      );
    }

    testWidgets('Active jobs opens My Jobs filtered to published',
        (tester) async {
      final container = await pump(tester);

      await tester.tap(find.byKey(const ValueKey('employerStat_activeJobs')));
      await tester.pumpAndSettle();

      expect(find.text('MY JOBS'), findsOne);
      expect(container.read(employerJobsFilterProvider).statuses,
          {JobStatus.published});
    });

    testWidgets('Applications opens Applicants with no status filter',
        (tester) async {
      final container = await pump(tester);

      await tester.tap(find.byKey(const ValueKey('employerStat_applications')));
      await tester.pumpAndSettle();

      expect(find.text('APPLICANTS'), findsOne);
      expect(container.read(employerApplicantsFilterProvider).statuses, isEmpty);
    });

    testWidgets('Interviews opens Applicants filtered to the interview stage',
        (tester) async {
      final container = await pump(tester);

      await tester.tap(find.byKey(const ValueKey('employerStat_interviews')));
      await tester.pumpAndSettle();

      expect(find.text('APPLICANTS'), findsOne);
      expect(container.read(employerApplicantsFilterProvider).statuses,
          {ApplicationStatus.interview});
    });

    testWidgets('Hires opens Applicants filtered to accepted', (tester) async {
      final container = await pump(tester);

      await tester.tap(find.byKey(const ValueKey('employerStat_hires')));
      await tester.pumpAndSettle();

      expect(find.text('APPLICANTS'), findsOne);
      expect(container.read(employerApplicantsFilterProvider).statuses,
          {ApplicationStatus.accepted});
    });

    testWidgets('every tile is tappable', (tester) async {
      await pump(tester);
      // The defect was structural: plain Containers with no gesture handling.
      // Four stat tiles, each wrapped in its own InkWell.
      for (final id in ['activeJobs', 'applications', 'interviews', 'hires']) {
        final tile = find.byKey(ValueKey('employerStat_$id'));
        expect(tile, findsOne, reason: 'stat tile $id is missing');
        expect(
          find.descendant(of: tile, matching: find.byType(InkWell)),
          findsOne,
          reason: '$id is not tappable — the defect was four plain Containers',
        );
      }
    });
  });

  group('filter primitives', () {
    test('showOnly replaces the status set rather than toggling', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(employerJobsFilterProvider.notifier);

      notifier.toggleStatus(JobStatus.draft);
      notifier.updateText('noise');
      notifier.showOnly({JobStatus.published});

      final filter = container.read(employerJobsFilterProvider);
      expect(filter.statuses, {JobStatus.published});
      expect(filter.text, isEmpty,
          reason: 'arriving from the dashboard must not inherit a stale search');
    });

    test('showOnly is idempotent, unlike toggleStatus', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(employerApplicantsFilterProvider.notifier);

      notifier.showOnly({ApplicationStatus.interview});
      notifier.showOnly({ApplicationStatus.interview});

      expect(container.read(employerApplicantsFilterProvider).statuses,
          {ApplicationStatus.interview});
    });
  });

  group('CV upload discoverability', () {
    testWidgets('Home offers an entry point named for the task', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          _stub('/cvs', RouteNames.cvLibrary, 'MY CVS'),
          _stub('/settings', RouteNames.settings, 'SETTINGS'),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(_storage),
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(user: _user)),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          theme: AppTheme.light(const Locale('en')),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: supportedLocales,
        ),
      ));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      // "Upload your CV" — not "Resume Analyzer", which is what made the
      // capability look absent.
      expect(find.text(l10n.homeUploadCv), findsOne);

      await tester.tap(find.text(l10n.homeUploadCv));
      await tester.pumpAndSettle();
      expect(find.text('MY CVS'), findsOne);
    });
  });
}
