import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/auth/presentation/email_verification_screen.dart';
import 'package:careerbridge/features/auth/presentation/welcome_screen.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'support/fake_auth.dart';

const _unverified = AppUser(
  uid: 'u1',
  method: AuthMethod.email,
  email: 'new@user.app',
  emailVerified: false,
);

Widget _host(FakeAuthRepository repo, Widget child) => ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
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

  Future<AppLocalizations> l10n() =>
      AppLocalizations.delegate.load(const Locale('en'));

  testWidgets('welcome offers email only — no Google', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final l = await l10n();

    await tester.pumpWidget(_host(FakeAuthRepository(), const WelcomeScreen()));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text(l.continueWithEmail), findsOneWidget);
    expect(find.textContaining('Google'), findsNothing);
  });

  testWidgets('verify screen shows the email and the three actions',
      (tester) async {
    final l = await l10n();
    await tester.pumpWidget(
        _host(FakeAuthRepository(user: _unverified), const EmailVerificationScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(l.verifyEmailTitle), findsOneWidget);
    expect(find.textContaining('new@user.app'), findsOneWidget);
    expect(find.text(l.verifyEmailContinue), findsOneWidget);
    expect(find.text(l.verifyEmailResend), findsOneWidget);
    expect(find.text(l.verifyEmailUseAnother), findsOneWidget);
  });

  testWidgets('Continue with an unverified email shows the not-yet message',
      (tester) async {
    final l = await l10n();
    await tester.pumpWidget(
        _host(FakeAuthRepository(user: _unverified), const EmailVerificationScreen()));
    // Let the one-shot entrance-animation timers fire (never pumpAndSettle).
    await tester.pump(const Duration(milliseconds: 700));

    await tester.tap(find.text(l.verifyEmailContinue));
    await tester.pump(); // reloadEmailVerified resolves (false)
    await tester.pump(const Duration(milliseconds: 500)); // snackbar animates in

    expect(find.text(l.verifyEmailNotYet), findsOneWidget);

    // Flush the snackbar's auto-dismiss timer so none stay pending.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Resend sends a verification email', (tester) async {
    final l = await l10n();
    final fake = FakeAuthRepository(user: _unverified);
    await tester.pumpWidget(_host(fake, const EmailVerificationScreen()));
    await tester.pump(const Duration(milliseconds: 700));

    await tester.tap(find.text(l.verifyEmailResend));
    await tester.pump(); // resend resolves
    await tester.pump(const Duration(milliseconds: 500)); // snackbar animates in

    expect(fake.sendVerificationCount, 1);
    expect(find.text(l.verifyEmailResent), findsOneWidget);

    // A cooldown Timer + snackbar timer are running; dispose the tree to cancel.
    await tester.pumpWidget(const SizedBox());
  });
}
