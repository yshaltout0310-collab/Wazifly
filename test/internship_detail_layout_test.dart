import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/shared/models/job.dart';
import 'package:careerbridge/shared/widgets/job_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

// An internship job with a paid stipend so the details card renders every
// label→value row (the row that previously risked character-by-character
// vertical wrapping when starved on a narrow layout).
final _internshipJob = Job.fromJson(const {
  'id': 'intern',
  'title': 'Flutter Developer Intern',
  'titleAr': 'متدرّب تطوير Flutter',
  'company': 'Northwind Apps',
  'location': 'Doha, Qatar',
  'locationAr': 'الدوحة، قطر',
  'employmentType': 'Internship',
  'seniority': 'Entry',
  'remote': false,
  'requiredSkills': ['Flutter', 'Dart', 'Git'],
  'description': 'Join our mobile team.',
  'descriptionAr': 'انضمّ إلى فريق الجوّال لدينا.',
  'internship': {
    'funding': 'paid',
    'category': 'software',
    'level': 'undergraduate',
    'duration': 'threeToSixMonths',
    'workMode': 'hybrid',
    'eligibility': 'universityStudents',
    'schedule': 'fullTime',
    'certificateProvided': true,
    'stipendAmount': 1200,
    'currency': 'USD',
  },
});

Widget _host(Locale locale, double width) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: JobDetailView(job: _internshipJob),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();

    // A comfortable width uses the side-by-side row; a narrow one (< 260px)
    // exercises the stacked fallback. Neither must overflow (which would throw).
    for (final width in const [360.0, 220.0]) {
      testWidgets('internship details render at ${width}px with no overflow ($tag)',
          (tester) async {
        await tester.pumpWidget(_host(locale, width));
        await tester.pump();

        expect(tester.takeException(), isNull);
        // The internship-details card is present (its section title renders).
        final l10n = await AppLocalizations.delegate.load(locale);
        expect(find.text(l10n.internshipDetailsSection), findsOneWidget);
      });
    }

    testWidgets('stipend shows QAR with the original USD ($tag)',
        (tester) async {
      await tester.pumpWidget(_host(locale, 360));
      await tester.pump();
      // 1200 USD -> QAR 4,368 (~ USD 1,200).
      expect(find.textContaining('QAR 4,368'), findsOneWidget);
      expect(find.textContaining('USD 1,200'), findsOneWidget);
    });
  }
}
