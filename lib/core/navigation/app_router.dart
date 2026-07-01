import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../localization/generated/app_localizations.dart';
import '../../features/auth/presentation/email_auth_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/auth/presentation/phone_auth_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/country_selection/presentation/country_selection_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/job_matching/presentation/job_matching_screen.dart';
import '../../features/language_selection/presentation/language_selection_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/resume_analyzer/presentation/resume_analyzer_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/user_type/presentation/user_type_selection_screen.dart';
import 'route_names.dart';

/// Declarative navigation graph for the Phase 1 flow:
///
///   Splash → Language → Country → Onboarding → Welcome
///         → (Email | Phone → OTP | Google) → User Type → Home
///
/// Screens advance with `context.goNamed(...)`; the splash chooses the entry
/// point from persisted state (onboarding, session, user type).
abstract final class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splashPath,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RouteNames.splashPath,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.languagePath,
        name: RouteNames.language,
        pageBuilder: _fade(const LanguageSelectionScreen()),
      ),
      GoRoute(
        path: RouteNames.countryPath,
        name: RouteNames.country,
        pageBuilder: _fade(const CountrySelectionScreen()),
      ),
      GoRoute(
        path: RouteNames.onboardingPath,
        name: RouteNames.onboarding,
        pageBuilder: (context, state) {
          final replay = state.uri
                  .queryParameters[OnboardingScreen.replayParam] ==
              'true';
          return _fadePage(
            OnboardingScreen(replay: replay),
            state.pageKey,
          );
        },
      ),
      GoRoute(
        path: RouteNames.welcomePath,
        name: RouteNames.welcome,
        pageBuilder: _fade(const WelcomeScreen()),
      ),
      GoRoute(
        path: RouteNames.emailAuthPath,
        name: RouteNames.emailAuth,
        pageBuilder: _fade(const EmailAuthScreen()),
      ),
      GoRoute(
        path: RouteNames.phoneAuthPath,
        name: RouteNames.phoneAuth,
        pageBuilder: _fade(const PhoneAuthScreen()),
      ),
      GoRoute(
        path: RouteNames.otpPath,
        name: RouteNames.otp,
        pageBuilder: (context, state) {
          final args = state.extra as OtpArgs;
          return _fadePage(OtpVerificationScreen(args: args), state.pageKey);
        },
      ),
      GoRoute(
        path: RouteNames.userTypePath,
        name: RouteNames.userType,
        pageBuilder: _fade(const UserTypeSelectionScreen()),
      ),
      GoRoute(
        path: RouteNames.homePath,
        name: RouteNames.home,
        pageBuilder: _fade(const HomeScreen()),
      ),
      GoRoute(
        path: RouteNames.resumeAnalyzerPath,
        name: RouteNames.resumeAnalyzer,
        pageBuilder: _fade(const ResumeAnalyzerScreen()),
      ),
      GoRoute(
        path: RouteNames.jobMatchingPath,
        name: RouteNames.jobMatching,
        pageBuilder: _fade(const JobMatchingScreen()),
      ),
      GoRoute(
        path: RouteNames.settingsPath,
        name: RouteNames.settings,
        pageBuilder: _fade(const SettingsScreen()),
        routes: [
          GoRoute(
            path: 'profile',
            name: RouteNames.profile,
            pageBuilder: _fade(const ProfileScreen()),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context).pageNotFound),
          ],
        ),
      ),
    ),
  );

  static Page<void> Function(BuildContext, GoRouterState) _fade(Widget child) =>
      (context, state) => _fadePage(child, state.pageKey);

  static Page<void> _fadePage(Widget child, LocalKey key) =>
      CustomTransitionPage<void>(
        key: key,
        child: child,
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        transitionsBuilder: (context, animation, secondary, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: const Cubic(0.2, 0.0, 0.0, 1.0),
            reverseCurve: Curves.easeIn,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.035),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );
}
