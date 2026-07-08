import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_service.dart';
import 'notification_service.dart';
import 'noop_notification_service.dart';

/// Background message handler. Must be a top-level / static function annotated
/// with `@pragma('vm:entry-point')` so it survives tree-shaking and can run in
/// its own isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Firebase Cloud Messaging implementation of [NotificationService] — the
/// **only** file that imports `firebase_messaging`. Absorbs the former
/// `MessagingService` and adds token-refresh + plain-value [PushMessage] mapping.
///
/// Kept as a singleton so `FirebaseService.initialize()` can bootstrap it at
/// startup (permission + token + listeners) and the provider can hand back the
/// same initialized instance. All work is wrapped in try/catch — a messaging
/// failure never propagates.
class FirebaseNotificationService implements NotificationService {
  FirebaseNotificationService._();
  static final FirebaseNotificationService instance =
      FirebaseNotificationService._();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  String? _token;
  @override
  String? get cachedToken => _token;

  @override
  Future<void> initialize() async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await requestPermission();
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      _token = await _messaging.getToken();
      debugPrint('[FCM] Token: $_token');
    } catch (e) {
      debugPrint('[FCM] init failed: $e');
    }
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final status = _mapPermission(settings.authorizationStatus);
      debugPrint('[FCM] Permission: ${status.name}');
      return status;
    } catch (e) {
      debugPrint('[FCM] permission failed: $e');
      return NotificationPermission.notDetermined;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return _token ??= await _messaging.getToken();
    } catch (e) {
      debugPrint('[FCM] getToken failed: $e');
      return null;
    }
  }

  @override
  Stream<String> get onTokenRefresh {
    try {
      return _messaging.onTokenRefresh;
    } catch (_) {
      return const Stream<String>.empty();
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _token = null;
    } catch (e) {
      debugPrint('[FCM] deleteToken failed: $e');
    }
  }

  @override
  Stream<PushMessage> get onMessage =>
      FirebaseMessaging.onMessage.map(_toPushMessage);

  @override
  Stream<PushMessage> get onMessageOpened =>
      FirebaseMessaging.onMessageOpenedApp.map(_toPushMessage);

  PushMessage _toPushMessage(RemoteMessage m) => PushMessage(
        messageId: m.messageId,
        title: m.notification?.title,
        body: m.notification?.body,
        data: m.data.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      );

  NotificationPermission _mapPermission(AuthorizationStatus s) => switch (s) {
        AuthorizationStatus.authorized => NotificationPermission.granted,
        AuthorizationStatus.provisional => NotificationPermission.provisional,
        AuthorizationStatus.denied => NotificationPermission.denied,
        AuthorizationStatus.notDetermined =>
          NotificationPermission.notDetermined,
      };
}

/// The app-wide notification service: the Firebase implementation when Firebase
/// is ready, else an inert no-op (so tests and unconfigured runs never touch the
/// plugin). Swap this binding to change providers.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => FirebaseService.instance.isReady
      ? FirebaseNotificationService.instance
      : const NoopNotificationService(),
);
