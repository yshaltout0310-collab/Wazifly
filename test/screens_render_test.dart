import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/core/services/storage/storage_keys.dart';
import 'package:careerbridge/features/home/presentation/home_screen.dart';
import 'package:careerbridge/features/language_selection/presentation/language_selection_screen.dart';
import 'package:careerbridge/features/profile/presentation/profile_screen.dart';
import 'package:careerbridge/features/settings/presentation/settings_screen.dart';
import 'package:careerbridge/features/user_type/presentation/user_type_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth.dart';

/// Renders the screens that are only reachable after real auth, so they're
/// covered even when Firebase isn't configured. Verifies they build without
/// throwing and show their key copy.
Future<LocalStorageService> _storage([Map<String, Object> seed = const {}]) {
  SharedPreferences.setMockInitialValues(seed);
  return LocalStorageService.create();
}

Widget _host(LocalStorageService storage, Widget child, {Locale? locale}) {
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
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
      home: child,
    ),
  );
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('UserTypeSelectionScreen renders both roles', (tester) async {
    final storage = await _storage();
    await tester.pumpWidget(
      _host(storage, const UserTypeSelectionScreen()),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.jobSeeker), findsOneWidget);
    expect(find.text(l10n.employer), findsOneWidget);
    expect(find.text(l10n.confirm), findsOneWidget);
  });

  testWidgets('HomeScreen renders dashboard with toolkit tiles',
      (tester) async {
    // Tall surface so the lazy toolkit grid (below the platform CTAs) is built
    // during the initial pump rather than needing a mid-test scroll.
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await _storage({StorageKeys.userType: 'jobSeeker'});
    await tester.pumpWidget(_host(storage, const HomeScreen()));
    await tester.pump(const Duration(milliseconds: 600));

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.homeToolkitTitle), findsOneWidget);
    expect(find.text(l10n.featResumeAnalyzer), findsOneWidget);
    expect(find.text(l10n.homeWelcome), findsOneWidget);
  });

  testWidgets('SettingsScreen renders all sections', (tester) async {
    final storage = await _storage();
    await tester.pumpWidget(_host(storage, const SettingsScreen()));
    await tester.pump(const Duration(milliseconds: 300));

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.settingsLanguage), findsOneWidget);
    expect(find.text(l10n.settingsNotifications), findsOneWidget);
    expect(find.text(l10n.logout), findsWidgets);
    expect(find.text(l10n.settingsRestartOnboarding), findsOneWidget);
  });

  testWidgets('Settings renders correctly in Arabic (RTL)', (tester) async {
    final storage = await _storage();
    await tester.pumpWidget(
      _host(storage, const SettingsScreen(), locale: const Locale('ar')),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(Directionality.of(tester.element(find.byType(SettingsScreen))),
        TextDirection.rtl);
    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(find.text(l10n.settingsLanguage), findsOneWidget);
  });

  testWidgets('ProfileScreen shows signed-out empty state', (tester) async {
    final storage = await _storage();
    await tester.pumpWidget(_host(storage, const ProfileScreen()));
    await tester.pump(const Duration(milliseconds: 300));

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.profileNotSignedIn), findsOneWidget);
  });

  testWidgets('Language search accepts input and filters in real time',
      (tester) async {
    final storage = await _storage();
    await tester.pumpWidget(
      _host(storage, const LanguageSelectionScreen()),
    );
    await tester.pump(const Duration(milliseconds: 400));

    // Both popular languages visible initially.
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('Arabic'), findsOneWidget);

    // Typing into the search field updates the filtered list.
    await tester.enterText(find.byType(TextField), 'arab');
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('العربية'), findsOneWidget); // still matches
    expect(find.text('English'), findsNothing); // filtered out
  });
}
