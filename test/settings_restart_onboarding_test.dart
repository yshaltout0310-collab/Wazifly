import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/navigation/route_names.dart';
import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/core/services/storage/storage_keys.dart';
import 'package:careerbridge/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth.dart';

/// End-to-end wiring for Settings → "Restart onboarding":
/// tap → confirm → onboarding flag cleared → routed to Splash (which begins the
/// first-launch flow). Pure Flutter, so it holds identically on Android and iOS.
Future<LocalStorageService> _storage(Map<String, Object> seed) {
  SharedPreferences.setMockInitialValues(seed);
  return LocalStorageService.create();
}

Widget _app(LocalStorageService storage) {
  final router = GoRouter(
    initialLocation: RouteNames.settingsPath,
    routes: [
      GoRoute(
        path: RouteNames.settingsPath,
        name: RouteNames.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.splashPath,
        name: RouteNames.splash,
        builder: (_, __) => const Scaffold(body: Text('SPLASH-REACHED')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
      fakeAuthOverride(),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
    ),
  );
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Restart onboarding: confirm resets the flag and goes to Splash',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // A user who has already finished onboarding, with other data present.
    final storage = await _storage({
      StorageKeys.onboardingCompleted: true,
      StorageKeys.languageCode: 'en',
      StorageKeys.selectedCountry: 'QA',
    });
    await tester.pumpWidget(_app(storage));
    await tester.pump(const Duration(milliseconds: 300));

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    // The new Settings item exists; bring it into view and tap it.
    final tile = find.text(l10n.settingsRestartOnboarding);
    await tester.scrollUntilVisible(tile, 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    // Confirmation dialog is shown.
    expect(find.text(l10n.restartOnboardingConfirmTitle), findsOneWidget);

    // Confirm.
    await tester.tap(find.text(l10n.restart));
    await tester.pumpAndSettle();

    // Onboarding flag cleared; other data preserved; landed on Splash.
    expect(storage.getBool(StorageKeys.onboardingCompleted), isFalse);
    expect(storage.getString(StorageKeys.languageCode), 'en');
    expect(storage.getString(StorageKeys.selectedCountry), 'QA');
    expect(find.text('SPLASH-REACHED'), findsOneWidget);
  });

  testWidgets('Restart onboarding: cancel changes nothing', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final storage = await _storage({StorageKeys.onboardingCompleted: true});
    await tester.pumpWidget(_app(storage));
    await tester.pump(const Duration(milliseconds: 300));

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final tile = find.text(l10n.settingsRestartOnboarding);
    await tester.scrollUntilVisible(tile, 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();

    // Nothing reset, still on Settings.
    expect(storage.getBool(StorageKeys.onboardingCompleted), isTrue);
    expect(find.text('SPLASH-REACHED'), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
