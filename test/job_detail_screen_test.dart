import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/theme/app_theme.dart';
import 'package:careerbridge/features/jobs/application/job_detail_controller.dart';
import 'package:careerbridge/features/jobs/presentation/job_detail_screen.dart';
import 'package:careerbridge/shared/models/internship_details.dart';
import 'package:careerbridge/shared/models/job.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const _job = Job(
  id: 'x',
  title: 'Senior Flutter Engineer',
  company: 'Cedar Labs',
  location: 'Dubai, UAE',
  employmentType: 'Full-time',
  seniority: 'Senior',
  description: 'Lead the mobile architecture and mentor engineers.',
  requiredSkills: ['Flutter', 'Dart', 'CI/CD'],
  remote: true,
);

Widget _host(Locale locale) {
  return ProviderScope(
    overrides: [
      jobDetailControllerProvider('x').overrideWith(
        (ref) => JobDetailController.seeded(
          ref,
          'x',
          const JobDetailState(status: JobDetailStatus.ready, job: _job),
        ),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      // Use the real AppTheme so the full-width themed button style (which forces
      // infinite width in an unbounded Row) is exercised — the regression guard
      // for the seeker _ActionBar bug (§7.14 pattern).
      theme: AppTheme.light(locale),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      home: const JobDetailScreen(jobId: 'x'),
    ),
  );
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();
    testWidgets('job detail renders in $tag with no overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(locale));
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull, reason: 'threw during render ($tag)');

      final dir =
          Directionality.of(tester.element(find.byType(JobDetailScreen)));
      expect(dir,
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr);

      expect(find.text('Senior Flutter Engineer'), findsOneWidget);
      expect(
          find.text('Lead the mobile architecture and mentor engineers.'),
          findsOneWidget);
      // A required-skill chip renders.
      expect(find.text('CI/CD'), findsOneWidget);
    });
  }

  testWidgets('internship detail renders the internship section + badges (EN)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const internJob = Job(
      id: 'x',
      title: 'Flutter Intern',
      company: 'Northwind',
      location: 'Doha, Qatar',
      employmentType: 'Internship',
      seniority: 'Entry',
      description: 'Learn Flutter under mentorship.',
      requiredSkills: ['Flutter'],
      remote: true,
      trainsBeginners: true,
      internship: InternshipDetails(
        funding: InternshipFunding.paid,
        workMode: WorkMode.hybrid,
        schedule: InternshipSchedule.fullTime,
        certificateProvided: true,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          jobDetailControllerProvider('x').overrideWith(
            (ref) => JobDetailController.seeded(
              ref,
              'x',
              const JobDetailState(
                  status: JobDetailStatus.ready, job: internJob),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(const Locale('en')),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: supportedLocales,
          home: const JobDetailScreen(jobId: 'x'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.internshipDetailsSection), findsOneWidget);
    expect(find.text(l10n.internshipBadge), findsWidgets);
    expect(find.text(l10n.trainsBeginnersBadge), findsWidgets);
    // A projected internship field value renders.
    expect(find.text(l10n.internshipFundingPaid), findsOneWidget);
  });
}
