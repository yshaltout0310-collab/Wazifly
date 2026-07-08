import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/navigation/app_router.dart';
import 'core/providers/app_providers.dart';
import 'core/services/analytics/analytics_consent.dart';
import 'core/services/analytics/analytics_events.dart';
import 'core/services/analytics/analytics_route_observer.dart';
import 'core/services/analytics/firebase_analytics_service.dart';
import 'core/services/crashlytics/firebase_crash_reporter.dart';
import 'core/services/firebase/firebase_service.dart';
import 'core/services/performance/firebase_performance_monitor.dart';
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

  // Load persisted preferences (theme, language, country, onboarding flag).
  final storage = await LocalStorageService.create();

  // Never blocks startup; no-ops if Firebase config is missing.
  await FirebaseService.instance.initialize();

  // One container shared by the bootstrap and the widget tree, so telemetry
  // services and the UI resolve the same provider instances.
  final container = ProviderContainer(
    overrides: [localStorageProvider.overrideWithValue(storage)],
  );

  await _bootstrapTelemetry(container);

  final router = AppRouter.create(
    observers: [AnalyticsRouteObserver(container.read(analyticsServiceProvider))],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: CareerBridgeApp(router: router),
    ),
  );
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

  // Keep telemetry consent in sync if it changes at runtime — no feature code
  // ever needs to branch on consent.
  container.listen<bool>(analyticsConsentControllerProvider, (_, enabled) {
    analytics.setEnabled(enabled);
  });

  _bindTelemetryUserContext(container);
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
