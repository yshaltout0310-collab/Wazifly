import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/shared/models/job.dart';
import 'package:careerbridge/shared/widgets/job_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const _job = Job(
  id: 'j1',
  title: 'Flutter Engineer',
  company: 'Acme',
  location: 'Doha',
  employmentType: 'Full-time',
  seniority: 'Senior',
  description: 'Build delightful mobile apps with Flutter and Dart.',
  requiredSkills: ['Flutter', 'Dart'],
  remote: true,
);

Widget _host(Locale locale, Widget child) => MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();
    testWidgets('renders a job body in $tag', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(locale, const JobDetailView(job: _job)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Flutter Engineer'), findsOneWidget);
      expect(find.text('Acme'), findsOneWidget);
      expect(find.text('Flutter'), findsWidgets);
    });
  }

  testWidgets('injects the afterMeta slot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host(
      const Locale('en'),
      const JobDetailView(
        job: _job,
        afterMeta: Text('MATCH-PANEL'),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('MATCH-PANEL'), findsOneWidget);
  });
}
