import 'package:careerbridge/core/services/analytics/analytics_route_observer.dart';
import 'package:careerbridge/core/services/analytics/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records screen views; other methods are inert.
class _RecordingAnalytics implements AnalyticsService {
  final List<String> screens = [];

  @override
  Future<void> logScreenView(String screenName) async => screens.add(screenName);

  @override
  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) async {}
  @override
  Future<void> setUserId(String? id) async {}
  @override
  Future<void> setUserProperty({required String name, required String? value}) async {}
  @override
  Future<void> setEnabled(bool enabled) async {}
}

Route<dynamic> _route(String? name) => MaterialPageRoute<void>(
      builder: (_) => const SizedBox.shrink(),
      settings: RouteSettings(name: name),
    );

void main() {
  test('logs a screen view with the route name on push', () {
    final analytics = _RecordingAnalytics();
    final observer = AnalyticsRouteObserver(analytics);

    observer.didPush(_route('home'), null);
    expect(analytics.screens, ['home']);
  });

  test('ignores unnamed routes', () {
    final analytics = _RecordingAnalytics();
    final observer = AnalyticsRouteObserver(analytics);

    observer.didPush(_route(null), null);
    expect(analytics.screens, isEmpty);
  });

  test('logs the revealed route name on pop', () {
    final analytics = _RecordingAnalytics();
    final observer = AnalyticsRouteObserver(analytics);

    observer.didPop(_route('detail'), _route('list'));
    expect(analytics.screens, ['list']);
  });
}
