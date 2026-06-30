import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Background message handler. Must be a top-level / static function annotated
/// with `@pragma('vm:entry-point')` so it survives tree-shaking and can run in
/// its own isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Prepares Firebase Cloud Messaging (push notifications).
///
/// Phase 1 wires the plumbing — permission request, token retrieval, and
/// foreground/opened listeners — but does not yet route notifications to
/// features. Called from [FirebaseService] only once Firebase is configured.
class MessagingService {
  MessagingService._();
  static final MessagingService instance = MessagingService._();

  String? _token;
  String? get token => _token;

  Future<void> initialize() async {
    try {
      final messaging = FirebaseMessaging.instance;

      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint(
        '[FCM] Permission: ${settings.authorizationStatus.name}',
      );

      // Show heads-up notifications while the app is in the foreground (iOS).
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _token = await messaging.getToken();
      debugPrint('[FCM] Token: $_token');

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('[FCM] Foreground: ${message.notification?.title}');
      });
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('[FCM] Opened from notification: ${message.messageId}');
      });
    } catch (e) {
      debugPrint('[FCM] init failed: $e');
    }
  }
}
