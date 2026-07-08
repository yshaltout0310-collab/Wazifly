import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_service.dart';
import 'crash_reporter.dart';
import 'noop_crash_reporter.dart';

/// Firebase Crashlytics implementation of [CrashReporter] — the **only** file
/// that imports `firebase_crashlytics`. All calls are guarded so a reporting
/// failure never propagates.
///
/// Note: the Crashlytics Gradle plugin (release mapping upload + NDK symbols) is
/// intentionally deferred (AGP 9 compatibility) — Dart/Flutter error reporting
/// works at runtime without it.
class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter([FirebaseCrashlytics? crashlytics])
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async {
    try {
      await _crashlytics.recordError(error, stack, reason: reason, fatal: fatal);
    } catch (e) {
      debugPrint('[Crashlytics] recordError failed: $e');
    }
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    try {
      await _crashlytics.recordFlutterError(details);
    } catch (e) {
      debugPrint('[Crashlytics] recordFlutterError failed: $e');
    }
  }

  @override
  Future<void> log(String message) async {
    try {
      await _crashlytics.log(message);
    } catch (e) {
      debugPrint('[Crashlytics] log failed: $e');
    }
  }

  @override
  Future<void> setUserIdentifier(String? id) async {
    try {
      await _crashlytics.setUserIdentifier(id ?? '');
    } catch (e) {
      debugPrint('[Crashlytics] setUserIdentifier failed: $e');
    }
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    try {
      await _crashlytics.setCustomKey(key, value);
    } catch (e) {
      debugPrint('[Crashlytics] setCustomKey failed: $e');
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
    } catch (e) {
      debugPrint('[Crashlytics] setEnabled failed: $e');
    }
  }
}

/// The app-wide crash reporter: Firebase when ready, else an inert no-op.
final crashReporterProvider = Provider<CrashReporter>(
  (ref) => FirebaseService.instance.isReady
      ? FirebaseCrashReporter()
      : const NoopCrashReporter(),
);
