import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/services/activity/employer_activity_repository.dart';
import 'package:careerbridge/core/services/activity/in_memory_employer_activity_repository.dart';
import 'package:careerbridge/core/services/applications/employer_applicants_repository.dart';
import 'package:careerbridge/core/services/applications/in_memory_employer_applicants_repository.dart';
import 'package:careerbridge/core/services/jobs/employer_jobs_repository.dart';
import 'package:careerbridge/core/services/jobs/in_memory_employer_jobs_repository.dart';
import 'package:careerbridge/core/services/notes/employer_notes_repository.dart';
import 'package:careerbridge/core/services/notes/in_memory_employer_notes_repository.dart';
import 'package:careerbridge/core/theme/app_theme.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/employer/presentation/employer_applicant_detail_screen.dart';
import 'package:careerbridge/features/employer/presentation/employer_applicants_screen.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/applicant_snapshot.dart';
import 'package:careerbridge/shared/models/application.dart';
import 'package:careerbridge/shared/models/application_note.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'support/fake_auth.dart';

const _user = AppUser(uid: 'emp1', method: AuthMethod.email, email: 'e@b.co');

Application _app(String id, ApplicationStatus status, String name) => Application(
      id: id,
      jobId: 'j1',
      jobTitle: 'Flutter Engineer',
      company: 'Acme',
      location: 'Doha',
      status: status,
      appliedAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 5),
      history: [
        ApplicationEvent(status: ApplicationStatus.pending, at: DateTime(2026, 7, 1)),
        if (status != ApplicationStatus.pending)
          ApplicationEvent(status: status, at: DateTime(2026, 7, 5)),
      ],
      applicantUid: 'seeker_$id',
      ownerUid: 'emp1',
      applicant: ApplicantSnapshot(
        name: name,
        headline: 'Mobile Engineer',
        location: 'Doha, Qatar',
        skills: const ['Flutter', 'Dart'],
        atsScore: 88,
        resumeSummary: 'Strong mobile background.',
        resumeStrengths: const ['Clear structure'],
        matchScore: 92,
        matchReason: 'Great fit for the role.',
        matchingSkills: const ['Flutter'],
        missingSkills: const ['Kubernetes'],
        interviewSessions: 3,
        interviewBestScore: 81,
      ),
    );

Widget _host(Locale locale, Widget child) => ProviderScope(
      overrides: [
        authRepositoryProvider
            .overrideWithValue(FakeAuthRepository(user: _user)),
        employerApplicantsRepositoryProvider.overrideWithValue(
          InMemoryEmployerApplicantsRepository(seed: [
            _app('a', ApplicationStatus.pending, 'Sara Ahmed'),
            _app('b', ApplicationStatus.interview, 'Omar Ali'),
          ]),
        ),
        employerNotesRepositoryProvider.overrideWithValue(
          InMemoryEmployerNotesRepository(seed: [
            ApplicationNote(
              id: 'n1',
              applicationId: 'a',
              ownerUid: 'emp1',
              text: 'Strong candidate',
              createdAt: DateTime(2026, 7, 6),
              updatedAt: DateTime(2026, 7, 6),
            ),
          ]),
        ),
        employerJobsRepositoryProvider
            .overrideWithValue(InMemoryEmployerJobsRepository()),
        employerActivityRepositoryProvider
            .overrideWithValue(InMemoryEmployerActivityRepository()),
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
        home: child,
      ),
    );

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  final screens = <String, (Widget, double)>{
    'ApplicantsInbox': (const EmployerApplicantsScreen(), 1600),
    'ApplicantsForJob': (const EmployerApplicantsScreen(jobId: 'j1'), 1600),
    'ApplicantDetail': (const EmployerApplicantDetailScreen(appId: 'a'), 2600),
  };

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();
    final expectedDir =
        locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    for (final entry in screens.entries) {
      final (widget, height) = entry.value;
      testWidgets('${entry.key} renders in $tag with no overflow',
          (tester) async {
        await tester.binding.setSurfaceSize(Size(412, height));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_host(locale, widget));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: '${entry.key} ($tag) threw');
        final dir =
            Directionality.of(tester.element(find.byType(widget.runtimeType)));
        expect(dir, expectedDir);
      });
    }
  }

  testWidgets('Inbox shows the seeded applicant name (EN)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester
        .pumpWidget(_host(const Locale('en'), const EmployerApplicantsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Sara Ahmed'), findsWidgets);
  });

  testWidgets('Detail shows match, resume, and a note (EN)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
        _host(const Locale('en'), const EmployerApplicantDetailScreen(appId: 'a')));
    await tester.pumpAndSettle();
    expect(find.text('Sara Ahmed'), findsWidgets);
    expect(find.text('Strong candidate'), findsOneWidget); // the seeded note
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.applicantMatchPercent(92)), findsWidgets);
  });
}
