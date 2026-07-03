import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/services/applications/in_memory_applications_repository.dart';
import 'package:careerbridge/features/applications/presentation/applications_screen.dart';
import 'package:careerbridge/shared/models/application.dart';
import 'package:careerbridge/shared/models/job.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

final _t = DateTime(2026, 1, 10);
Job _job(String id, String title) => Job(
      id: id,
      title: title,
      company: 'Northwind Apps',
      location: 'Doha',
      employmentType: 'Full-time',
      seniority: 'Mid',
      description: 'x',
      requiredSkills: const ['Flutter'],
      remote: false,
    );

final _apps = <Application>[
  Application.create(id: 'a1', job: _job('j1', 'Flutter Mobile Engineer'), now: _t),
  Application.create(id: 'a2', job: _job('j2', 'Backend Engineer'), now: _t)
      .withStatus(ApplicationStatus.interview, _t),
];

Widget _host(Locale locale) {
  return ProviderScope(
    overrides: [
      applicationsProvider.overrideWith((ref) => Stream.value(_apps)),
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
      home: const ApplicationsScreen(),
    ),
  );
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();
    testWidgets('applications hub renders in $tag with no overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(locale));
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull, reason: 'threw during render ($tag)');

      final dir =
          Directionality.of(tester.element(find.byType(ApplicationsScreen)));
      expect(dir,
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr);

      // Applications listed + stats header present.
      expect(find.text('Flutter Mobile Engineer'), findsOneWidget);
      expect(find.text('Backend Engineer'), findsOneWidget);
      final l10n = await AppLocalizations.delegate.load(locale);
      expect(find.text(l10n.statApplied), findsOneWidget);
    });
  }
}
