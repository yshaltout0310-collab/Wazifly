import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/features/cv_builder/application/cv_draft_store.dart';
import 'package:careerbridge/features/cv_builder/domain/cv_data.dart';
import 'package:careerbridge/features/cv_builder/presentation/cv_builder_screen.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'support/fake_auth.dart';

const _user = AppUser(uid: 'u1', method: AuthMethod.email, displayName: 'Sarah');
const _draft = CvData(
  fullName: 'Sarah Ahmed',
  headline: 'Flutter Engineer',
  skills: ['Flutter'],
);

Widget _host(Locale locale) {
  final store = InMemoryCvDraftStore()..write(_draft);
  return ProviderScope(
    overrides: [
      fakeAuthOverride(user: _user),
      cvDraftStoreProvider.overrideWithValue(store),
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
      home: const CvBuilderScreen(),
    ),
  );
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();
    testWidgets('CV builder renders in $tag with seeded data', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(locale));
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull, reason: 'threw ($tag)');
      final dir = Directionality.of(tester.element(find.byType(CvBuilderScreen)));
      expect(dir,
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr);

      final l10n = await AppLocalizations.delegate.load(locale);
      expect(find.text('Sarah Ahmed'), findsOneWidget); // seeded contact field
      expect(find.text(l10n.cvEnhanceWithAi), findsOneWidget);
      expect(find.text(l10n.cvTemplateAts), findsWidgets); // picker card
    });
  }
}
