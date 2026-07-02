// ignore_for_file: prefer_const_literals_to_create_immutables
import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/features/job_matching/application/job_matching_controller.dart';
import 'package:careerbridge/shared/models/job.dart';
import 'package:careerbridge/features/job_matching/domain/job_match.dart';
import 'package:careerbridge/features/job_matching/presentation/job_matching_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

final _matches = <JobMatch>[
  const JobMatch(
    job: Job(
      id: 'a',
      title: 'Flutter Engineer',
      company: 'Northwind Apps',
      location: 'Doha, Qatar',
      employmentType: 'Full-time',
      seniority: 'Mid',
      description: 'Build apps',
      requiredSkills: ['Flutter', 'Dart'],
      remote: false,
    ),
    matchScore: 92,
    reason: 'Strong Flutter and Firebase alignment.',
    matchingSkills: ['Flutter', 'Dart'],
    missingSkills: ['Kotlin'],
  ),
  const JobMatch(
    job: Job(
      id: 'b',
      title: 'Backend Engineer',
      company: 'Cedar Labs',
      location: 'Remote',
      employmentType: 'Contract',
      seniority: 'Senior',
      description: 'Build services',
      requiredSkills: ['Node.js'],
      remote: true,
    ),
    matchScore: 48,
    reason: 'Partial overlap in tooling.',
    matchingSkills: ['Git'],
    missingSkills: ['Node.js', 'PostgreSQL'],
  ),
];

Widget _host(Locale locale) {
  return ProviderScope(
    overrides: [
      jobMatchingControllerProvider.overrideWith(
        (ref) => JobMatchingController.seeded(
          ref,
          JobMatchingState(
            status: JobMatchStatus.success,
            matches: _matches,
          ),
        ),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      home: const JobMatchingScreen(),
    ),
  );
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();
    testWidgets('ranked matches render in $tag with no overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(locale));
      await tester.pump(const Duration(milliseconds: 800));

      expect(tester.takeException(), isNull,
          reason: 'threw during render ($tag)');

      final dir =
          Directionality.of(tester.element(find.byType(JobMatchingScreen)));
      expect(dir,
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr);

      // Job content + score badges rendered.
      expect(find.text('Flutter Engineer'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);
      expect(find.text('48%'), findsOneWidget);
    });
  }
}
