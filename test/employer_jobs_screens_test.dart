import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/services/company/company_repository.dart';
import 'package:careerbridge/core/services/company/in_memory_company_repository.dart';
import 'package:careerbridge/core/services/jobs/employer_jobs_repository.dart';
import 'package:careerbridge/core/services/jobs/in_memory_employer_jobs_repository.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/employer/domain/employment_type.dart';
import 'package:careerbridge/features/employer/domain/job_experience.dart';
import 'package:careerbridge/features/employer/domain/job_status.dart';
import 'package:careerbridge/features/employer/presentation/employer_job_detail_screen.dart';
import 'package:careerbridge/features/employer/presentation/employer_jobs_screen.dart';
import 'package:careerbridge/features/employer/presentation/job_editor_screen.dart';
import 'package:careerbridge/features/employer/presentation/job_preview_screen.dart';
import 'package:careerbridge/core/theme/app_theme.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/company.dart';
import 'package:careerbridge/shared/models/job_posting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'support/fake_auth.dart';

const _user = AppUser(uid: 'c1', method: AuthMethod.email, email: 'a@b.co');

JobPosting _posting() => JobPosting(
      id: 'a',
      companyId: 'c1',
      ownerUid: 'c1',
      companyName: 'Acme',
      title: 'Flutter Engineer',
      description: 'Build delightful mobile apps with Flutter and Dart daily.',
      requiredSkills: const ['Flutter', 'Dart'],
      location: 'Doha, Qatar',
      remote: true,
      employmentType: EmploymentType.fullTime,
      experience: JobExperience.senior,
      status: JobStatus.published,
      openings: 2,
      publishedAt: DateTime(2026, 7, 5),
      updatedAt: DateTime(2026, 7, 5),
    );

Widget _host(Locale locale, Widget child) => ProviderScope(
      overrides: [
        authRepositoryProvider
            .overrideWithValue(FakeAuthRepository(user: _user)),
        companyRepositoryProvider.overrideWithValue(InMemoryCompanyRepository(
            seed: [Company.empty('c1').copyWith(name: 'Acme')])),
        employerJobsRepositoryProvider.overrideWithValue(
            InMemoryEmployerJobsRepository(seed: [_posting()])),
      ],
      child: MaterialApp(
        locale: locale,
        // Use the real AppTheme so theme-driven layout (e.g. full-width button
        // minimumSize) is exercised — a bare MaterialApp masks those bugs.
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
    'EmployerJobs': (const EmployerJobsScreen(), 1600),
    'JobEditor': (const JobEditorScreen(), 2400),
    'JobDetail': (const EmployerJobDetailScreen(jobId: 'a'), 1600),
    'JobPreview': (JobPreviewScreen(posting: _posting()), 1600),
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

  testWidgets('My Jobs shows the seeded posting title (EN)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host(const Locale('en'), const EmployerJobsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Flutter Engineer'), findsWidgets);
  });

  testWidgets('Preview shows the Publish CTA for a publishable posting (EN)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // A draft is publishable → the Publish bar renders.
    final draft = _posting().copyWith(status: JobStatus.draft);
    await tester
        .pumpWidget(_host(const Locale('en'), JobPreviewScreen(posting: draft)));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.jobPublish), findsOneWidget);
  });
}
