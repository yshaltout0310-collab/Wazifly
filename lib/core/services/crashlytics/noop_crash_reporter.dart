import 'package:flutter/foundation.dart';

import 'crash_reporter.dart';

/// Inert [CrashReporter] for tests, debug, and unconfigured runs — records
/// nothing and never touches the Crashlytics plugin.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async {}

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {}

  @override
  Future<void> log(String message) async {}

  @override
  Future<void> setUserIdentifier(String? id) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}

  @override
  Future<void> setEnabled(bool enabled) async {}
}
