import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/services/biometric/biometric_providers.dart';
import 'package:careerbridge/core/services/biometric/biometric_service.dart';
import 'package:careerbridge/core/services/secure_store/in_memory_secure_store.dart';
import 'package:careerbridge/core/services/secure_store/secure_store_provider.dart';
import 'package:careerbridge/features/security/presentation/security_settings_screen.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';
import 'support/fake_biometric.dart';

void main() {
  const user = AppUser(uid: 'u1', method: AuthMethod.email, email: 'a@b.com');

  Widget host({required BiometricCapability capability}) {
    return ProviderScope(
      overrides: [
        fakeAuthOverride(user: user),
        biometricServiceProvider
            .overrideWithValue(FakeBiometricService(cap: capability)),
        secureStoreProvider.overrideWithValue(InMemorySecureStore()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: supportedLocales,
        home: const SecuritySettingsScreen(),
      ),
    );
  }

  testWidgets('shows an enabled toggle when biometrics are available',
      (tester) async {
    await tester.pumpWidget(host(capability: BiometricCapability.available));
    await tester.pumpAndSettle();

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    final toggle = tester.widget<Switch>(switchFinder);
    expect(toggle.onChanged, isNotNull); // interactive
  });

  testWidgets('disables the toggle with a hint when not enrolled',
      (tester) async {
    await tester.pumpWidget(host(capability: BiometricCapability.notEnrolled));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.securityBiometricNotEnrolled), findsOneWidget);
    final toggle = tester.widget<Switch>(find.byType(Switch));
    expect(toggle.onChanged, isNull); // disabled — never blocks access
  });

  testWidgets('hides the toggle entirely when unavailable', (tester) async {
    await tester.pumpWidget(host(capability: BiometricCapability.unavailable));
    await tester.pumpAndSettle();

    expect(find.byType(Switch), findsNothing);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.securityBiometricUnavailable), findsOneWidget);
  });
}
