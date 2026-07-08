import 'notification_service.dart';

/// Inert [NotificationService] for tests and unconfigured runs — never touches
/// the messaging plugin and emits nothing.
class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Future<void> initialize() async {}

  @override
  Future<NotificationPermission> requestPermission() async =>
      NotificationPermission.notDetermined;

  @override
  Future<String?> getToken() async => null;

  @override
  String? get cachedToken => null;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<PushMessage> get onMessage => const Stream<PushMessage>.empty();

  @override
  Stream<PushMessage> get onMessageOpened => const Stream<PushMessage>.empty();
}
