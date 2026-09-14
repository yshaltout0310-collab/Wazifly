import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'core/navigation/app_router.dart';
import 'core/providers/app_providers.dart';
import 'core/services/analytics/analytics_consent.dart';
import 'core/services/analytics/analytics_events.dart';
import 'core/services/analytics/analytics_route_observer.dart';
import 'core/services/analytics/firebase_analytics_service.dart';
import 'core/services/app_check/firebase_app_check_service.dart';
import 'core/services/build_info/build_info.dart';
import 'core/services/crashlytics/firebase_crash_reporter.dart';
import 'core/services/firebase/firebase_service.dart';
import 'core/services/performance/firebase_performance_monitor.dart';
import 'core/services/security/security_audit_log.dart';
import 'core/services/storage/local_storage_service.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/user_type/application/user_type_controller.dart';

/// Application entry point.
///
/// Bootstraps persistence, Firebase, and the production telemetry stack
/// (Crashlytics error handlers, Analytics consent, Performance), then runs the
/// app. Every telemetry step is best-effort and wrapped so it can never block or
/// break startup (the M1 telemetry principle).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The UI theme uses the Inter/Cairo fonts bundled under assets/fonts (see
  // AppTypography), so it never needs the network for fonts. This is a
  // belt-and-suspenders guard: it forbids google_fonts from ever fetching at
  // runtime, keeping a cold OFFLINE first launch correct (no FOUT/fallback).
  GoogleFonts.config.allowRuntimeFetching = false;

  // Load persisted preferences (theme, language, country, onboarding flag).
  final storage = await LocalStorageService.create();

  // Never blocks startup; no-ops if Firebase config is missing.
  await FirebaseService.instance.initialize();

  // One container shared by the bootstrap and the widget tree, so telemetry
  // services and the UI resolve the same provider instances.
  final container = ProviderContainer(
    overrides: [localStorageProvider.overrideWithValue(storage)],
  );

  final router = AppRouter.create(
    observers: [AnalyticsRouteObserver(container.read(analyticsServiceProvider))],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: WaziflyApp(router: router),
    ),
  );

  // Telemetry is best-effort and must never delay the first frame. Running it
  // after runApp keeps the web shell responsive even when a Firebase plugin is
  // unavailable or slow to resolve on the target platform.
  unawaited(_bootstrapTelemetry(container));

  // Attest the app instance (App Check) — deliberately AFTER runApp and NOT
  // awaited, so attestation never delays the first frame (the mandated
  // "App Check must never block startup"). Token fetch is lazy; the first
  // backend read tolerates the brief unattested window (and, with enforcement
  // off, a placeholder token). A failure records + continues, app stays usable.
  unawaited(_bootstrapAppCheck(container));
}

/// Wires Crashlytics error handlers, applies analytics consent, enables
/// performance collection, and binds the authenticated user's context to
/// telemetry. All best-effort.
Future<void> _bootstrapTelemetry(ProviderContainer container) async {
  final crash = container.read(crashReporterProvider);
  final analytics = container.read(analyticsServiceProvider);
  final performance = container.read(performanceMonitorProvider);

  // Route uncaught Flutter + platform errors to Crashlytics (non-blocking).
  final priorOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    priorOnError?.call(details);
    crash.recordFlutterError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    crash.recordError(error, stack, fatal: true);
    return true;
  };

  // Apply persisted analytics consent (opt-out foundation) + enable perf/crash.
  final consentEnabled = container.read(analyticsConsentControllerProvider);
  await analytics.setEnabled(consentEnabled);
  await performance.setEnabled(true);
  await crash.setEnabled(true);

  // Stamp every crash report with the release build metadata (bug-report reuse
  // of the BuildInfo foundation) — best-effort.
  final build = container.read(buildInfoProvider);
  await crash.setCustomKey('app_version', build.fullVersion);
  await crash.setCustomKey('build_type', build.buildType.name);

  // Keep telemetry consent in sync if it changes at runtime — no feature code
  // ever needs to branch on consent.
  container.listen<bool>(analyticsConsentControllerProvider, (_, enabled) {
    analytics.setEnabled(enabled);
  });

  _bindTelemetryUserContext(container);
}

/// Activates Firebase App Check (device attestation) so the backend can reject
/// requests from tampered clients / scrapers. Best-effort: if activation fails
/// or App Check is unavailable, the app keeps running **unattested** and the
/// failure is recorded via Crashlytics + the security audit log — the app must
/// remain usable (App Check is monitored, not enforced, until the Console
/// enforcement switch is flipped — see HANDOFF §5).
Future<void> _bootstrapAppCheck(ProviderContainer container) async {
  final appCheck = container.read(appCheckServiceProvider);
  final ok = await appCheck.activate();
  if (!ok) {
    await container.read(securityAuditLogProvider).record(
          SecurityEventType.appCheckFailure,
          detail: 'activation_failed',
        );
    return;
  }

  // Debug builds only: request one token so the platform SDK emits the App
  // Check **debug secret** to the device log.
  //
  // `activate()` only installs the debug provider — token minting is lazy, so
  // on a debug build that has not yet hit an attested backend the secret is
  // never printed and there is nothing to paste into the Firebase Console.
  // Since that registration is a prerequisite for the debug provider being
  // accepted at all, force it here rather than leaving developers to hunt for
  // a log line that never appears.
  //
  // The secret is printed by the native SDK (Android tag
  // `DebugAppCheckProvider`) and is deliberately NEVER logged from Dart, never
  // written to a file, and never committed — it is a credential.
  // Release builds skip this entirely: they attest with Play Integrity /
  // Device Check and mint tokens on demand.
  if (kDebugMode) {
    await appCheck.getToken();
  }
}

/// Associates crash reports + analytics with the signed-in user (id + account
/// type), reacting to auth and role changes. Best-effort.
void _bindTelemetryUserContext(ProviderContainer container) {
  void apply() {
    final crash = container.read(crashReporterProvider);
    final analytics = container.read(analyticsServiceProvider);
    final uid = container.read(authStateProvider).valueOrNull?.uid;
    final accountType = container.read(userTypeControllerProvider)?.name;

    crash.setUserIdentifier(uid);
    analytics.setUserId(uid);
    if (accountType != null) {
      crash.setCustomKey(AnalyticsUserProperties.accountType, accountType);
      analytics.setUserProperty(
        name: AnalyticsUserProperties.accountType,
        value: accountType,
      );
    }
  }

  container.listen(authStateProvider, (_, __) => apply(), fireImmediately: true);
  container.listen(userTypeControllerProvider, (_, __) => apply(),
      fireImmediately: true);
}
