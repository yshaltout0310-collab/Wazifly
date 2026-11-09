import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/services/applications/employer_applicants_repository.dart';
import 'package:careerbridge/core/services/company/company_repository.dart';
import 'package:careerbridge/core/services/company/in_memory_company_repository.dart';
import 'package:careerbridge/core/services/jobs/employer_jobs_repository.dart';
import 'package:careerbridge/core/theme/app_theme.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/employer/presentation/employer_applicants_screen.dart';
import 'package:careerbridge/features/employer/presentation/employer_jobs_screen.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/application.dart';
import 'package:careerbridge/shared/models/company.dart';
import 'package:careerbridge/shared/models/job_posting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

/// Proves the *user-visible* half of the stream-error fix.
///
/// Before it, the Firestore repositories ended their `.snapshots()` pipeline in
/// `.handleError((e) { debugPrint(...); })`, which consumes the error without
/// forwarding it. Firestore's stream terminates on error, so the provider
/// received no value and no error and stayed in `AsyncLoading` **forever** —
/// these screens showed a spinner that never resolved, with no diagnostic and
/// no way to retry. (That is what the client reported as "Manage Jobs loads
/// indefinitely" and "Applications page loads indefinitely".)
///
/// Each test asserts both halves of the contract: the error state **is** shown,
/// and the endless spinner is **gone**.

const _user = AppUser(uid: 'c1', method: AuthMethod.email, email: 'a@b.co');

/// A repository whose stream fails the way a rules denial or an App Check
/// rejection fails in production.
class _FailingJobsRepository implements EmployerJobsRepository {
  @override
  Stream<List<JobPosting>> watchJobs(String companyId) =>
      Stream<List<JobPosting>>.error(StateError('permission-denied'));

  @override
  Future<JobPosting?> fetchJob(String id) async => null;

  @override
  Future<JobPosting> createJob(JobPosting posting) async => posting;

  @override
  Future<void> updateJob(JobPosting posting) async {}
}

class _FailingApplicantsRepository implements EmployerApplicantsRepository {
  @override
  Stream<List<Application>> watchApplicants(String ownerUid) =>
      Stream<List<Application>>.error(StateError('permission-denied'));

  @override
  Future<Application?> fetchApplicant(String id) async => null;

  @override
  Future<void> updateApplication(Application application) async {}
}

Widget _host(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: [
        authRepositoryProvider
            .overrideWithValue(FakeAuthRepository(user: _user)),
        companyRepositoryProvider.overrideWithValue(InMemoryCompanyRepository(
            seed: [Company.empty('c1').copyWith(name: 'Acme')])),
        ...overrides,
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        theme: AppTheme.light(const Locale('en')),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: supportedLocales,
        home: child,
      ),
    );

void main() {
  testWidgets('Manage Jobs shows a retryable error instead of hanging',
      (tester) async {
    await tester.pumpWidget(_host(
      const EmployerJobsScreen(),
      overrides: [
        employerJobsRepositoryProvider
            .overrideWithValue(_FailingJobsRepository()),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load your data. Please try again."), findsOne);
    expect(find.text('Try again'), findsOne);
    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: 'the endless spinner is the exact bug being fixed',
    );
  });

  testWidgets('Applicants shows a retryable error instead of hanging',
      (tester) async {
    await tester.pumpWidget(_host(
      const EmployerApplicantsScreen(),
      overrides: [
        employerApplicantsRepositoryProvider
            .overrideWithValue(_FailingApplicantsRepository()),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load your data. Please try again."), findsOne);
    expect(find.text('Try again'), findsOne);
    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: 'the endless spinner is the exact bug being fixed',
    );
  });

  testWidgets('a healthy empty stream still shows the empty state, not an error',
      (tester) async {
    await tester.pumpWidget(_host(
      const EmployerJobsScreen(),
      overrides: [
        employerJobsRepositoryProvider
            .overrideWithValue(_EmptyJobsRepository()),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load your data. Please try again."), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

/// A healthy repository with nothing in it — guards against the error state
/// swallowing the legitimate "no jobs yet" case.
class _EmptyJobsRepository implements EmployerJobsRepository {
  @override
  Stream<List<JobPosting>> watchJobs(String companyId) =>
      Stream<List<JobPosting>>.value(const []);

  @override
  Future<JobPosting?> fetchJob(String id) async => null;

  @override
  Future<JobPosting> createJob(JobPosting posting) async => posting;

  @override
  Future<void> updateJob(JobPosting posting) async {}
}
