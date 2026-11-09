import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'core/navigation/app_router.dart';
import 'core/providers/app_providers.dart';
import 'core/services/ai/ai_providers.dart';
import 'core/services/analytics/analytics_consent.dart';
import 'core/services/analytics/analytics_events.dart';
import 'core/services/analytics/analytics_route_observer.dart';
import 'core/services/analytics/firebase_analytics_service.dart';
import 'core/services/app_check/app_check_service.dart';
import 'core/services/app_check/firebase_app_check_service.dart';
import 'core/services/build_info/build_info.dart';
import 'core/services/crashlytics/firebase_crash_reporter.dart';
import 'core/services/cv_repository/last_selected_cv.dart';
import 'core/services/firebase/firebase_service.dart';
import 'core/services/messaging/firebase_notification_service.dart';
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

  await _bootstrapTelemetry(container);

  final router = AppRouter.create(
    observers: [AnalyticsRouteObserver(container.read(analyticsServiceProvider))],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: WaziflyApp(router: router),
    ),
  );

  // Attest the app instance (App Check) — deliberately AFTER runApp and NOT
  // awaited, so attestation never delays the first frame (the mandated
  // "App Check must never block startup"). Token fetch is lazy; the first
  // backend read tolerates the brief unattested window (and, with enforcement
  // off, a placeholder token). A failure records + continues, app stays usable.
  unawaited(_bootstrapAppCheck(container));

  // Push notifications — after the first frame and never awaited, for the same
  // reason as App Check.
  //
  // This used to run inside `FirebaseService.initialize()`, which `main`
  // awaits BEFORE `runApp`. Messaging's `initialize()` awaits
  // `requestPermission()`, and on web that is the browser's own notification
  // prompt: it does not resolve until the visitor answers, so ignoring the
  // prompt meant never getting a first frame — a blank page for as long as the
  // tab stayed open. On web the provider now hands back the no-op service
  // anyway (browser push needs a service worker this app does not ship).
  unawaited(_bootstrapNotifications(container));
}

/// Starts Cloud Messaging (permission, token, listeners). Best-effort and
/// non-blocking: a messaging failure must never affect startup.
Future<void> _bootstrapNotifications(ProviderContainer container) async {
  try {
    await container.read(notificationServiceProvider).initialize();
  } catch (e) {
    debugPrint('[Notifications] bootstrap failed: $e');
  }
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
  _bindUserScopedStateToAuth(container);
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
    await _logAppCheckTokenHealth(appCheck);
    if (_aiSelfTestEnabled) await _runAiSelfTest(container);
  }
}

/// Opt-in end-to-end probe of the Firebase AI Logic path, enabled with
/// `--dart-define=AI_SELFTEST=true` on a debug build. Off by default so normal
/// debug runs spend no quota.
///
/// It exercises the real request path (the same `aiServiceProvider` every AI
/// feature uses) rather than mocking it, because the failure modes that matter
/// here — a missing App Check header, an unregistered debug secret, AI Logic
/// disabled project-wide — are all invisible until an actual request reaches
/// the backend. Being independent of sign-in, it isolates the AI/attestation
/// path from auth and navigation when triaging on a physical device.
const bool _aiSelfTestEnabled = bool.fromEnvironment('AI_SELFTEST');

Future<void> _runAiSelfTest(ProviderContainer container) async {
  debugPrint('[AiSelfTest] sending a live Firebase AI Logic request...');
  try {
    final reply = await container
        .read(aiServiceProvider)
        .generateText('Reply with the single word OK.');
    debugPrint('[AiSelfTest] SUCCESS - model replied '
        '(${reply.length} chars): ${reply.trim()}');
  } catch (e) {
    debugPrint('[AiSelfTest] FAILED: $e');
  }
}

/// Debug-only attestation probe.
///
/// Forces a fresh App Check token and reports **only whether one could be
/// obtained** — never the token, never a prefix of it, since an App Check token
/// is a bearer credential. This exists because the symptom of an unregistered
/// debug secret, a disabled App Check API, or a wrong provider is identical at
/// the call site (`Firebase App Check token is invalid.` from the backend) and
/// otherwise indistinguishable from a transport error.
///
/// `forceRefresh: true` deliberately bypasses the platform SDK's token cache,
/// so a stale token minted before a Console change cannot mask the real state:
/// a failure here is a live attestation failure, not a cached one.
Future<void> _logAppCheckTokenHealth(AppCheckService appCheck) async {
  final token = await appCheck.getToken(forceRefresh: true);
  if (token == null || token.isEmpty) {
    debugPrint('[AppCheck] DIAGNOSTIC: no token (attestation FAILED). On a '
        'debug build, register the debug secret printed above by the native '
        'DebugAppCheckProvider in Firebase Console > App Check > Apps > this '
        'Android app > Manage debug tokens. Every AI Logic request will be '
        'rejected until then.');
    return;
  }
  // The SDK hands out a short placeholder token instead of failing when
  // attestation is unavailable and enforcement is off; it is a JWT whose
  // payload is an error object, and it is always far shorter than a real token.
  final looksPlaceholder = token.length < 100;
  debugPrint('[AppCheck] DIAGNOSTIC: token acquired '
      '(length ${token.length}${looksPlaceholder ? ', LOOKS LIKE A '
          'PLACEHOLDER - attestation did not really succeed' : ''}).');
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

/// Drops user-scoped in-memory state when the signed-in account **changes**.
///
/// Firebase Auth's web persistence is per-origin and shared by every tab of the
/// site, so signing in as somebody else in a second tab makes *this* tab's auth
/// stream emit the new user. The persisted role cache is already scoped to its
/// owning uid, but the copy held in memory is not: without this, the previous
/// account's role survives the switch and the UI keeps rendering their
/// dashboard.
///
/// Deliberately narrow. It fires on uid → *different* uid, and on uid → null
/// (sign-out). A null → uid transition is an ordinary sign-in, where
/// `goAfterAuth` is already resolving the role from Firestore — clearing there
/// would race it and drop the user on role selection.
void _bindUserScopedStateToAuth(ProviderContainer container) {
  String? previousUid = container.read(authStateProvider).valueOrNull?.uid;

  container.listen(authStateProvider, (_, next) {
    final uid = next.valueOrNull?.uid;
    final switched = previousUid != null && previousUid != uid;
    previousUid = uid;
    if (!switched) return;

    unawaited(container.read(userTypeControllerProvider.notifier).clear());
    unawaited(container.read(lastSelectedCvProvider.notifier).clear());
  });
}
