import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/theme/app_theme.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/auth/domain/auth_exception.dart';
import 'package:careerbridge/features/auth/presentation/email_auth_screen.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

/// Guards the sign-in / sign-up password validation split.
///
/// One validator used to serve both modes, so a *wrong* password shorter than
/// six characters was rejected locally as "Password must be at least 6
/// characters": a creation-time rule pre-empting the credentials check. The
/// user was told the wrong thing, and because local validation runs before
/// `_submit` does anything, the request never left the device — which is the
/// reported "incorrect login password shows a password-length message".

/// Records sign-in / sign-up attempts so a test can assert whether the request
/// was actually sent, and can fail them the way Firebase does.
class _RecordingAuth extends FakeAuthRepository {
  _RecordingAuth({this.signInError});

  final Object? signInError;
  int signInCount = 0;
  int registerCount = 0;

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signInCount++;
    if (signInError != null) throw signInError!;
    return super.signInWithEmail(email: email, password: password);
  }

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
  }) async {
    registerCount++;
    return super.registerWithEmail(email: email, password: password);
  }
}

Widget _host(_RecordingAuth auth) => ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
      child: MaterialApp(
        locale: const Locale('en'),
        theme: AppTheme.light(const Locale('en')),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: supportedLocales,
        home: const EmailAuthScreen(),
      ),
    );

Future<void> _fill(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), password);
}

void main() {
  testWidgets('sign-in sends a short wrong password and reports bad credentials',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final auth = _RecordingAuth(
      signInError: const AuthException(AuthErrorCode.invalidCredentials),
    );
    await tester.pumpWidget(_host(auth));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await _fill(tester, 'a@b.co', '123');
    await tester.tap(find.text(l10n.signIn));
    await tester.pumpAndSettle();

    expect(
      auth.signInCount,
      1,
      reason: 'the credentials check must actually run — the creation-time '
          'length rule used to block it locally',
    );
    expect(find.text(l10n.errInvalidCredentials), findsOne);
    expect(find.text(l10n.passwordTooShort), findsNothing);
    expect(find.text(l10n.passwordRequirementsUnmet), findsNothing);
  });

  testWidgets('sign-in does not show the creation-time requirements checklist',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host(_RecordingAuth()));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.passwordRequirementsTitle), findsNothing);
  });

  testWidgets('sign-up states the requirements up front and blocks a weak one',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final auth = _RecordingAuth();
    await tester.pumpWidget(_host(auth));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    // Toggle to sign-up (before the toggle, "Sign up" is only the link).
    await tester.tap(find.text(l10n.signUp));
    await tester.pumpAndSettle();

    // Stated before the user types anything, which is the whole point: the
    // requirement used to be discoverable only by violating it.
    expect(find.text(l10n.passwordRequirementsTitle), findsOne);
    expect(find.text(l10n.passwordRuleLetter), findsOne);
    expect(find.text(l10n.passwordRuleNumber), findsOne);

    await _fill(tester, 'a@b.co', 'abc');
    await tester.tap(find.text(l10n.signUp).last);
    await tester.pumpAndSettle();

    expect(auth.registerCount, 0);
    expect(find.text(l10n.passwordRequirementsUnmet), findsOne);
  });

  testWidgets('sign-up accepts a password that meets the policy',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final auth = _RecordingAuth();
    await tester.pumpWidget(_host(auth));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.text(l10n.signUp));
    await tester.pumpAndSettle();

    await _fill(tester, 'a@b.co', 'passw0rdy');
    await tester.tap(find.text(l10n.signUp).last);
    await tester.pump();

    expect(auth.registerCount, 1);
  });
}
