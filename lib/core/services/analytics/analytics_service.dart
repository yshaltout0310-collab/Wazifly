/// Provider-agnostic product analytics (the single Firebase Analytics boundary).
///
/// Only `FirebaseAnalyticsService` imports `firebase_analytics`; swap the backend
/// by rebinding `analyticsServiceProvider`. Distinct from the employer hiring
/// **Analytics feature** (`employerAnalyticsProvider`) — this is platform
/// telemetry.
///
/// Every method is **best-effort and non-throwing** (fire-and-forget): a
/// telemetry failure must never affect the app (the M1 telemetry principle).
/// [setEnabled] is the consent lever — collection can be turned on/off at runtime
/// without any feature-code change.
abstract interface class AnalyticsService {
  Future<void> logScreenView(String screenName);

  Future<void> logEvent(String name, {Map<String, Object?>? parameters});

  Future<void> setUserId(String? id);

  Future<void> setUserProperty({required String name, required String? value});

  /// Enables/disables collection (analytics consent). Feature code keeps calling
  /// [logEvent] regardless — this gates delivery centrally.
  Future<void> setEnabled(bool enabled);
}
