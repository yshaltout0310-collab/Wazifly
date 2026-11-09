import 'dart:io';

import 'package:careerbridge/core/theme/app_dimensions.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the web startup path.
///
/// These are source and constant guards rather than behavioural tests on
/// purpose: the defects they cover are invisible to a widget test. Tests run on
/// the Dart VM where `kIsWeb` is false, and the symptom — the first frame never
/// arriving because a browser permission prompt is being awaited — only exists
/// in a browser. A source guard is the only thing that stops it coming back.
void main() {
  test('FirebaseService does not bootstrap messaging', () {
    // `FirebaseService.initialize()` is awaited before `runApp`. Messaging's
    // own `initialize()` awaits `requestPermission()`, which on web is the
    // browser's native notification prompt and does not resolve until the
    // visitor answers it — so a visitor who ignored the prompt never got a
    // first frame at all, just a blank page. Messaging must start after
    // `runApp`, un-awaited.
    final source =
        File('lib/core/services/firebase/firebase_service.dart').readAsStringSync();

    final offending = source
        .split('\n')
        .asMap()
        .entries
        .where((e) =>
            !e.value.trimLeft().startsWith('//') &&
            e.value.contains('NotificationService'))
        .map((e) => 'line ${e.key + 1}')
        .toList();

    expect(
      offending,
      isEmpty,
      reason: 'messaging must not be initialized from the pre-runApp path: '
          '$offending',
    );
  });

  test('the notification provider no-ops on web', () {
    // Browser push needs a `firebase-messaging-sw.js` service worker and a VAPID
    // key, neither of which this app ships, so the real implementation can only
    // fail on web — and asking for the permission is what stalled startup.
    final source = File(
            'lib/core/services/messaging/firebase_notification_service.dart')
        .readAsStringSync();

    expect(source, contains('kIsWeb'));
    expect(source, contains('NoopNotificationService()'));
  });

  group('web/index.html first-paint placeholder', () {
    late String html;

    setUpAll(() => html = File('web/index.html').readAsStringSync());

    test('paints something before Flutter does', () {
      // Until Flutter's first frame the page is whatever this document says it
      // is. An empty <body> meant a blank white page for the entire
      // multi-megabyte download, which is indistinguishable from a broken site.
      expect(html, contains('wazifly-loader'));
      expect(html, contains('<div id="wazifly-loader"'));
    });

    test('is removed once Flutter paints, so it cannot linger', () {
      expect(html, contains('flutter-first-frame'));
      expect(html, contains('removeChild'));
    });

    test('needs no network request of its own', () {
      // Inline styles and script only: a placeholder that waited on a request
      // of its own would defeat the point.
      expect(html, contains('<style>'));
      expect(
        RegExp(r'<link[^>]+stylesheet').hasMatch(html),
        isFalse,
        reason: 'an external stylesheet would delay the very paint this exists '
            'to deliver',
      );
    });
  });

  test('the native splash duration is unchanged', () {
    // Only the web value was shortened. This pins the native one so a future
    // edit cannot quietly cut the branded splash on installed builds, where it
    // is the first thing that happens rather than an addition to a download.
    expect(AppDurations.splash, const Duration(milliseconds: 2400));
  });
}
