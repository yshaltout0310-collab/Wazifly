import 'analytics_service.dart';

/// Inert [AnalyticsService] for tests, debug, and unconfigured runs — records
/// nothing and never touches the analytics plugin.
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> logScreenView(String screenName) async {}

  @override
  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) async {}

  @override
  Future<void> setUserId(String? id) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {}

  @override
  Future<void> setEnabled(bool enabled) async {}
}
