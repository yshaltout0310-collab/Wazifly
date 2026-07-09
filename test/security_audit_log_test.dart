import 'package:careerbridge/core/services/analytics/analytics_events.dart';
import 'package:careerbridge/core/services/analytics/analytics_service.dart';
import 'package:careerbridge/core/services/crashlytics/crash_reporter.dart';
import 'package:careerbridge/core/services/security/security_audit_log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the analytics events it receives.
class _RecordingAnalytics implements AnalyticsService {
  final events = <MapEntry<String, Map<String, Object?>?>>[];

  @override
  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) async {
    events.add(MapEntry(name, parameters));
  }

  @override
  Future<void> logScreenView(String screenName) async {}
  @override
  Future<void> setUserId(String? id) async {}
  @override
  Future<void> setUserProperty(
      {required String name, required String? value}) async {}
  @override
  Future<void> setEnabled(bool enabled) async {}
}

/// Records crash-reporter interactions.
class _RecordingCrash implements CrashReporter {
  final logs = <String>[];
  Object? lastError;
  String? lastReason;

  @override
  Future<void> log(String message) async => logs.add(message);

  @override
  Future<void> recordError(Object error, StackTrace? stack,
      {bool fatal = false, String? reason}) async {
    lastError = error;
    lastReason = reason;
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {}
  @override
  Future<void> setUserIdentifier(String? id) async {}
  @override
  Future<void> setCustomKey(String key, Object value) async {}
  @override
  Future<void> setEnabled(bool enabled) async {}
}

void main() {
  test('routes a security event to Analytics + a Crashlytics breadcrumb', () async {
    final analytics = _RecordingAnalytics();
    final crash = _RecordingCrash();
    final log = TelemetrySecurityAuditLog(analytics, crash);

    await log.record(SecurityEventType.permissionDenied, detail: 'jobs_read');

    expect(analytics.events, hasLength(1));
    final event = analytics.events.single;
    expect(event.key, AnalyticsEvents.securityEvent);
    expect(event.value?[AnalyticsParams.eventType], 'permission_denied');
    expect(event.value?[AnalyticsParams.reason], 'jobs_read');
    expect(crash.logs, hasLength(1));
    expect(crash.logs.single, contains('permission_denied'));
    expect(crash.lastError, isNull); // no error object → no non-fatal
  });

  test('files a Crashlytics non-fatal when an error is supplied', () async {
    final analytics = _RecordingAnalytics();
    final crash = _RecordingCrash();
    final log = TelemetrySecurityAuditLog(analytics, crash);
    final err = Exception('boom');

    await log.record(SecurityEventType.appCheckFailure,
        detail: 'activation_failed', error: err, stack: StackTrace.current);

    expect(crash.lastError, same(err));
    expect(crash.lastReason, 'security_app_check_failure');
    expect(analytics.events.single.value?[AnalyticsParams.eventType],
        'app_check_failure');
  });

  test('merges extra data into the analytics params', () async {
    final analytics = _RecordingAnalytics();
    final log = TelemetrySecurityAuditLog(analytics, _RecordingCrash());

    await log.record(SecurityEventType.authFailure,
        data: {'code': 'wrong_password'});

    expect(analytics.events.single.value?['code'], 'wrong_password');
    expect(analytics.events.single.value?[AnalyticsParams.eventType],
        'auth_failure');
  });

  test('NoopSecurityAuditLog never throws', () async {
    const log = NoopSecurityAuditLog();
    await log.record(SecurityEventType.ruleViolation,
        detail: 'x', error: Exception('y'), stack: StackTrace.current);
  });

  test('every SecurityEventType has a snake_case wire name', () {
    final valid = RegExp(r'^[a-z][a-z0-9_]*$');
    for (final t in SecurityEventType.values) {
      expect(valid.hasMatch(t.wireName), isTrue, reason: t.name);
    }
  });
}
