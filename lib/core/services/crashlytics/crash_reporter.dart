import 'package:flutter/foundation.dart';

/// Provider-agnostic crash + non-fatal error reporting (the single Firebase
/// Crashlytics boundary). Only `FirebaseCrashReporter` imports
/// `firebase_crashlytics`; swap the backend by rebinding `crashReporterProvider`.
///
/// Every method is **best-effort and non-throwing** — a reporting failure must
/// never affect the app (the M1 telemetry principle). [FlutterErrorDetails] is a
/// framework type (not a vendor type), so the interface stays vendor-neutral.
abstract interface class CrashReporter {
  /// Records a caught error as a non-fatal (or fatal) report.
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  });

  /// Records an uncaught framework error (from `FlutterError.onError`).
  Future<void> recordFlutterError(FlutterErrorDetails details);

  /// Adds a breadcrumb log line to the next report.
  Future<void> log(String message);

  /// Associates subsequent reports with a user id (cleared with null).
  Future<void> setUserIdentifier(String? id);

  /// Attaches a custom key/value to subsequent reports (e.g. account type).
  Future<void> setCustomKey(String key, Object value);

  /// Enables/disables collection (honored for consent / debug).
  Future<void> setEnabled(bool enabled);
}
