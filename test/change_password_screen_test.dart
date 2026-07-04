import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/features/profile/presentation/change_password_screen.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'support/fake_auth.dart';

const _user = AppUser(uid: 'u1', method: AuthMethod.email, email: 'a@cb.app');

Widget _host(Locale locale) {
  return ProviderScope(
    overrides: [fakeAuthOverride(user: _user)],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      home: const ChangePasswordScreen(),
    ),
  );
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();
    testWidgets('change password renders in $tag', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(locale));
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull, reason: 'threw ($tag)');
      final dir = Directionality.of(
          tester.element(find.byType(ChangePasswordScreen)));
      expect(dir,
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr);

      final l10n = await AppLocalizations.delegate.load(locale);
      expect(find.text(l10n.changePasswordSubmit), findsOneWidget);
      expect(find.text(l10n.changePasswordCurrent), findsOneWidget);
    });

    testWidgets('shows a validation error for mismatched passwords ($tag)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(locale));
      await tester.pump(const Duration(milliseconds: 400));

      final l10n = await AppLocalizations.delegate.load(locale);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'oldpass');
      await tester.enterText(fields.at(1), 'newpass1');
      await tester.enterText(fields.at(2), 'different');
      await tester.tap(find.text(l10n.changePasswordSubmit));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(l10n.changePasswordMismatch), findsOneWidget);
    });
  }
}
