import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_service.dart';
import 'analytics_service.dart';
import 'noop_analytics_service.dart';

/// Firebase Analytics implementation of [AnalyticsService] — the **only** file
/// that imports `firebase_analytics`. All calls are wrapped in try/catch and
/// fire-and-forget so telemetry never blocks or breaks a user action.
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService([FirebaseAnalytics? analytics])
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('[Analytics] logScreenView failed: $e');
    }
  }

  @override
  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: _sanitize(parameters));
    } catch (e) {
      debugPrint('[Analytics] logEvent($name) failed: $e');
    }
  }

  @override
  Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
    } catch (e) {
      debugPrint('[Analytics] setUserId failed: $e');
    }
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('[Analytics] setUserProperty failed: $e');
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(enabled);
    } catch (e) {
      debugPrint('[Analytics] setEnabled failed: $e');
    }
  }

  /// Firebase event params accept only String/num values; drop nulls and coerce
  /// anything else to a string so a bad param can never throw.
  Map<String, Object>? _sanitize(Map<String, Object?>? params) {
    if (params == null || params.isEmpty) return null;
    final out = <String, Object>{};
    params.forEach((k, v) {
      if (v == null) return;
      out[k] = (v is num || v is String) ? v : v.toString();
    });
    return out.isEmpty ? null : out;
  }
}

/// The app-wide analytics service: Firebase when ready, else an inert no-op.
/// Consent is applied at bootstrap via [AnalyticsService.setEnabled], so feature
/// code never branches on it.
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => FirebaseService.instance.isReady
      ? FirebaseAnalyticsService()
      : const NoopAnalyticsService(),
);
