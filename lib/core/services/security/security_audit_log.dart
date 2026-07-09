import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics_events.dart';
import '../analytics/analytics_service.dart';
import '../analytics/firebase_analytics_service.dart';
import '../crashlytics/crash_reporter.dart';
import '../crashlytics/firebase_crash_reporter.dart';

/// Categories of security-sensitive events worth an audit trail. Kept a small,
/// stable enum (like `AnalyticsEvents`) so callers stay stringly-typed-free and
/// the values line up across Analytics + Crashlytics.
enum SecurityEventType {
  /// A sign-in / re-auth attempt was rejected (bad credentials, blocked, etc.).
  authFailure,

  /// A Firestore/Storage operation was denied by the security rules.
  permissionDenied,

  /// A write was rejected for violating a rule's data contract (shape/size).
  ruleViolation,

  /// App Check activation or token acquisition failed / was unavailable.
  appCheckFailure,

  /// Anything else security-relevant that doesn't fit the buckets above.
  other,
}

extension SecurityEventTypeName on SecurityEventType {
  /// snake_case wire name (Analytics param value / Crashlytics key suffix).
  String get wireName {
    switch (this) {
      case SecurityEventType.authFailure:
        return 'auth_failure';
      case SecurityEventType.permissionDenied:
        return 'permission_denied';
      case SecurityEventType.ruleViolation:
        return 'rule_violation';
      case SecurityEventType.appCheckFailure:
        return 'app_check_failure';
      case SecurityEventType.other:
        return 'other';
    }
  }
}

/// Records security-sensitive events through the existing telemetry stack — the
/// **foundation** for auditing auth failures, permission-denied operations, rule
/// violations, and App Check failures. No UI; this is a write-only seam.
///
/// Vendor-neutral like the rest of `core/services`: it composes the existing
/// [AnalyticsService] (a typed event) and [CrashReporter] (a breadcrumb, plus a
/// non-fatal report when an error object is supplied). Every method is
/// **best-effort and non-throwing** — an audit failure must never affect the app
/// (the M1 telemetry principle). Swap the backend by rebinding
/// [securityAuditLogProvider]; feature code only ever calls [record].
abstract interface class SecurityAuditLog {
  /// Records a security event. [detail] is a short, non-PII descriptor (e.g. the
  /// denied collection or an auth error code); [data] adds structured params;
  /// [error]/[stack], when present, also file a Crashlytics non-fatal.
  Future<void> record(
    SecurityEventType type, {
    String? detail,
    Map<String, Object?>? data,
    Object? error,
    StackTrace? stack,
  });
}

/// Routes security events to Analytics (a `security_event` typed event) and
/// Crashlytics (a breadcrumb + optional non-fatal). Both delegates are already
/// best-effort/no-op when unconfigured, so this stays inert in tests/debug.
class TelemetrySecurityAuditLog implements SecurityAuditLog {
  const TelemetrySecurityAuditLog(this._analytics, this._crash);

  final AnalyticsService _analytics;
  final CrashReporter _crash;

  @override
  Future<void> record(
    SecurityEventType type, {
    String? detail,
    Map<String, Object?>? data,
    Object? error,
    StackTrace? stack,
  }) async {
    final params = <String, Object?>{
      AnalyticsParams.eventType: type.wireName,
      if (detail != null) AnalyticsParams.reason: detail,
      ...?data,
    };
    // Analytics: a single typed event, dimensioned by type (best-effort).
    await _analytics.logEvent(AnalyticsEvents.securityEvent, parameters: params);
    // Crashlytics: always a breadcrumb; a non-fatal when we have an error object
    // so the report carries a stack trace for triage.
    await _crash.log('security_event ${type.wireName}'
        '${detail != null ? ' ($detail)' : ''}');
    if (error != null) {
      await _crash.recordError(error, stack,
          reason: 'security_${type.wireName}');
    }
  }
}

/// Inert [SecurityAuditLog] for tests / unconfigured runs — records nothing.
class NoopSecurityAuditLog implements SecurityAuditLog {
  const NoopSecurityAuditLog();

  @override
  Future<void> record(
    SecurityEventType type, {
    String? detail,
    Map<String, Object?>? data,
    Object? error,
    StackTrace? stack,
  }) async {}
}

/// The app-wide security audit log. Composes the current analytics + crash
/// services (each already Firebase-or-Noop), so it needs no `isReady` gate.
/// Rebind this one provider to change where audit events go.
final securityAuditLogProvider = Provider<SecurityAuditLog>(
  (ref) => TelemetrySecurityAuditLog(
    ref.watch(analyticsServiceProvider),
    ref.watch(crashReporterProvider),
  ),
);
