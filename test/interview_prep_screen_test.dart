import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/features/interview_prep/presentation/interview_prep_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth.dart';

late LocalStorageService _storage;

Widget _host(Locale locale) {
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(_storage),
      fakeAuthOverride(),
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
      home: const InterviewPrepScreen(),
    ),
  );
}

void main() {
  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    _storage = await LocalStorageService.create();
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();
    testWidgets('interview setup renders in $tag with type options',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(locale));
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull, reason: 'threw ($tag)');
      final dir =
          Directionality.of(tester.element(find.byType(InterviewPrepScreen)));
      expect(dir,
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr);

      final l10n = await AppLocalizations.delegate.load(locale);
      expect(find.text(l10n.interviewTypeHr), findsOneWidget);
      expect(find.text(l10n.interviewTypeTechnical), findsOneWidget);
      expect(find.text(l10n.interviewStart), findsOneWidget);
    });
  }
}
