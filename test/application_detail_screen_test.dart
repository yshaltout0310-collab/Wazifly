import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/features/applications/application/applications_controller.dart';
import 'package:careerbridge/features/applications/presentation/application_detail_screen.dart';
import 'package:careerbridge/shared/models/application.dart';
import 'package:careerbridge/shared/models/job.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const _job = Job(
  id: 'j1',
  title: 'Senior Flutter Engineer',
  company: 'Cedar Labs',
  location: 'Dubai',
  employmentType: 'Full-time',
  seniority: 'Senior',
  description: 'x',
  requiredSkills: ['Flutter'],
  remote: true,
);

final _app = Application.create(id: 'x', job: _job, now: DateTime(2026, 1, 10))
    .withStatus(ApplicationStatus.interview, DateTime(2026, 1, 12));

Widget _host(Locale locale) {
  return ProviderScope(
    overrides: [
      applicationByIdProvider('x').overrideWithValue(_app),
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
      home: const ApplicationDetailScreen(applicationId: 'x'),
    ),
  );
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();
    testWidgets('application detail renders in $tag with no overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(locale));
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull, reason: 'threw during render ($tag)');

      final dir = Directionality.of(
          tester.element(find.byType(ApplicationDetailScreen)));
      expect(dir,
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr);

      expect(find.text('Senior Flutter Engineer'), findsWidgets);
      final l10n = await AppLocalizations.delegate.load(locale);
      expect(find.text(l10n.appsUpdateStatus), findsOneWidget);
      expect(find.text(l10n.appsHistory), findsOneWidget);
      // Interview-stage → coach prep CTA visible.
      expect(find.text(l10n.appsPrepareInterview), findsOneWidget);
    });
  }
}
