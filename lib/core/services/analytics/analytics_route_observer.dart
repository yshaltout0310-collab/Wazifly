import 'package:flutter/widgets.dart';

import 'analytics_service.dart';

/// Logs a `screen_view` whenever the top route changes. Vendor-neutral: it calls
/// the [AnalyticsService] abstraction (deliberately **not**
/// `FirebaseAnalyticsObserver`), so screen-view tracking works with any backend
/// and honors the consent lever. Wired into `GoRouter(observers: [...])`.
///
/// Screen names come from `route.settings.name`, which `go_router` sets to the
/// route's declared name (see `RouteNames`). Best-effort — never throws.
class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this._analytics);

  final AnalyticsService _analytics;

  void _log(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null || name.isEmpty) return;
    _analytics.logScreenView(name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _log(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _log(newRoute);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _log(previousRoute);
}
