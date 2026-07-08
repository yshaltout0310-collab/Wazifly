import 'package:careerbridge/core/services/analytics/analytics_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('event names satisfy Firebase Analytics constraints', () {
    // snake_case, start with a letter, ≤ 40 chars.
    final valid = RegExp(r'^[a-z][a-z0-9_]{0,39}$');
    for (final e in AnalyticsEvents.all) {
      expect(valid.hasMatch(e), isTrue, reason: '"$e" is not a valid event name');
      // Reserved prefixes are disallowed by Firebase.
      expect(e.startsWith('firebase_'), isFalse, reason: e);
      expect(e.startsWith('google_'), isFalse, reason: e);
      expect(e.startsWith('ga_'), isFalse, reason: e);
    }
  });

  test('event names are unique', () {
    expect(AnalyticsEvents.all.toSet().length, AnalyticsEvents.all.length);
  });
}
