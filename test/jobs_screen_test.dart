// ignore_for_file: prefer_const_literals_to_create_immutables
import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/features/jobs/application/jobs_browse_controller.dart';
import 'package:careerbridge/features/jobs/presentation/jobs_screen.dart';
import 'package:careerbridge/shared/models/job.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

final _jobs = <Job>[
  const Job(
    id: 'a',
    title: 'Flutter Mobile Engineer',
    company: 'Northwind Apps',
    location: 'Doha, Qatar',
    employmentType: 'Full-time',
    seniority: 'Mid',
    description: 'Build apps',
    requiredSkills: ['Flutter', 'Dart'],
    remote: false,
  ),
  const Job(
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
];

Widget _host(Locale locale) {
  return ProviderScope(
    overrides: [
      jobsBrowseControllerProvider.overrideWith(
        (ref) => JobsBrowseController.seeded(
          ref,
          JobsBrowseState(
            status: JobsStatus.ready,
            allJobs: _jobs,
            results: _jobs,
            typeOptions: ['Full-time', 'Contract'],
            seniorityOptions: ['Mid', 'Senior'],
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
      home: const JobsScreen(),
    ),
  );
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();
    testWidgets('jobs list renders in $tag with no overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(locale));
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull, reason: 'threw during render ($tag)');

      final dir = Directionality.of(tester.element(find.byType(JobsScreen)));
      expect(dir,
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr);

      expect(find.text('Flutter Mobile Engineer'), findsOneWidget);
      expect(find.text('Backend Engineer'), findsOneWidget);
    });
  }
}
