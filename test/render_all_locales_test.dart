import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/core/services/storage/storage_keys.dart';
import 'package:careerbridge/features/auth/presentation/email_auth_screen.dart';
import 'package:careerbridge/features/auth/presentation/otp_verification_screen.dart';
import 'package:careerbridge/features/auth/presentation/phone_auth_screen.dart';
import 'package:careerbridge/features/auth/presentation/welcome_screen.dart';
import 'package:careerbridge/features/country_selection/presentation/country_selection_screen.dart';
import 'package:careerbridge/features/applications/presentation/applications_screen.dart';
import 'package:careerbridge/features/career_coach/presentation/career_coach_screen.dart';
import 'package:careerbridge/features/home/presentation/home_screen.dart';
import 'package:careerbridge/features/job_matching/presentation/job_matching_screen.dart';
import 'package:careerbridge/features/jobs/presentation/jobs_screen.dart';
import 'package:careerbridge/features/language_selection/presentation/language_selection_screen.dart';
import 'package:careerbridge/features/onboarding/presentation/onboarding_screen.dart';
import 'package:careerbridge/features/profile/presentation/profile_screen.dart';
import 'package:careerbridge/features/resume_analyzer/presentation/resume_analyzer_screen.dart';
import 'package:careerbridge/features/settings/presentation/settings_screen.dart';
import 'package:careerbridge/features/user_type/presentation/user_type_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth.dart';

/// Renders every screen in both English (LTR) and Arabic (RTL) and asserts they
/// build with no exceptions or layout overflow, and pick up the right text
/// direction. This is the durable backbone of the QA pass — it covers screens
/// that are otherwise only reachable after real Firebase auth.

Future<LocalStorageService> _storage([Map<String, Object> seed = const {}]) {
  SharedPreferences.setMockInitialValues(seed);
  return LocalStorageService.create();
}

Widget _host(LocalStorageService storage, Widget child, Locale locale) {
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

  // A realistic tall-phone surface so Column/Spacer layouts don't false-overflow
  // on the default 800x600 test window.
  Future<void> usePhoneSurface(WidgetTester tester) =>
      tester.binding.setSurfaceSize(const Size(412, 915));

  final screens = <String, Widget Function()>{
    'Language': () => const LanguageSelectionScreen(),
    'Country': () => const CountrySelectionScreen(),
    'Onboarding': () => const OnboardingScreen(),
    'Welcome': () => const WelcomeScreen(),
    'EmailAuth': () => const EmailAuthScreen(),
    'PhoneAuth': () => const PhoneAuthScreen(),
    'Otp': () => const OtpVerificationScreen(
          args: OtpArgs(verificationId: 'vid', phoneNumber: '+97412345678'),
        ),
    'UserType': () => const UserTypeSelectionScreen(),
    'Home': () => const HomeScreen(),
    'Settings': () => const SettingsScreen(),
    'Profile': () => const ProfileScreen(),
    'ResumeAnalyzer': () => const ResumeAnalyzerScreen(),
    'JobMatching': () => const JobMatchingScreen(),
    'CareerCoach': () => const CareerCoachScreen(),
    'Jobs': () => const JobsScreen(),
    'Applications': () => const ApplicationsScreen(),
  };

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();
    final expectedDir =
        locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    for (final entry in screens.entries) {
      testWidgets('${entry.key} renders in $tag with no overflow',
          (tester) async {
        await usePhoneSurface(tester);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final storage = await _storage({StorageKeys.userType: 'jobSeeker'});
        await tester.pumpWidget(_host(storage, entry.value(), locale));
        // Let entrance animations play without relying on pumpAndSettle
        // (some screens have looping pulse animations).
        await tester.pump(const Duration(milliseconds: 700));

        // No build/layout/paint exceptions (RenderFlex overflow surfaces here).
        expect(tester.takeException(), isNull,
            reason: '${entry.key} ($tag) threw during render');

        // Correct text direction is applied for the locale.
        final dir = Directionality.of(
          tester.element(find.byType(entry.value().runtimeType)),
        );
        expect(dir, expectedDir,
            reason: '${entry.key} ($tag) has wrong text direction');
      });
    }
  }

  testWidgets('Email form shows validation errors on empty submit (EN)',
      (tester) async {
    await usePhoneSurface(tester);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final storage = await _storage();
    await tester.pumpWidget(_host(storage, const EmailAuthScreen(), const Locale('en')));
    await tester.pump(const Duration(milliseconds: 400));

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    // Tapping Sign In with empty fields surfaces "required" validation.
    await tester.tap(find.text(l10n.signIn));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(l10n.fieldRequired), findsWidgets);
  });

  testWidgets('Email form rejects an invalid email address (EN)',
      (tester) async {
    await usePhoneSurface(tester);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final storage = await _storage();
    await tester.pumpWidget(_host(storage, const EmailAuthScreen(), const Locale('en')));
    await tester.pump(const Duration(milliseconds: 400));

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final fields = find.byType(TextFormField);

    await tester.enterText(fields.first, 'not-an-email');
    await tester.enterText(fields.last, '123456');
    await tester.tap(find.text(l10n.signIn));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(l10n.invalidEmail), findsOneWidget);
  });
}
