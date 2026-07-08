import 'package:careerbridge/core/services/messaging/noop_notification_service.dart';
import 'package:careerbridge/core/services/messaging/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NoopNotificationService is inert and never throws', () async {
    const s = NoopNotificationService();
    await s.initialize();
    expect(await s.requestPermission(), NotificationPermission.notDetermined);
    expect(await s.getToken(), isNull);
    expect(s.cachedToken, isNull);
    expect(await s.onMessage.isEmpty, isTrue);
    expect(await s.onMessageOpened.isEmpty, isTrue);
    expect(await s.onTokenRefresh.isEmpty, isTrue);
    await s.deleteToken();
  });

  test('PushMessage carries plain values', () {
    const m = PushMessage(
      messageId: 'm1',
      title: 'Hi',
      body: 'Body',
      data: {'route': '/jobs'},
    );
    expect(m.messageId, 'm1');
    expect(m.data['route'], '/jobs');
  });
}
