import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/features/settings/application/notification_preferences_store.dart';
import 'package:careerbridge/features/settings/application/notifications_controller.dart';
import 'package:careerbridge/features/settings/domain/notification_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LocalStorageService> _storage([Map<String, Object> seed = const {}]) {
  SharedPreferences.setMockInitialValues(seed);
  return LocalStorageService.create();
}

void main() {
  test('effective getters gate categories behind the master toggle', () {
    const on = NotificationPreferences();
    expect(on.effectiveJobAlerts, isTrue);

    final masterOff = on.copyWith(master: false);
    expect(masterOff.effectiveJobAlerts, isFalse);
    expect(masterOff.effectiveApplicationUpdates, isFalse);
    expect(masterOff.effectiveCoachTips, isFalse);
  });

  test('store round-trips preferences through SharedPreferences', () async {
    final storage = await _storage();
    final store = LocalNotificationPreferencesStore(storage);

    // Defaults are all-on for a fresh install.
    expect(store.read(), const NotificationPreferences());

    await store.write(const NotificationPreferences(
        master: true, jobAlerts: false, applicationUpdates: true, coachTips: false));

    // A fresh store reading the same backing prefs sees the persisted values.
    final reloaded = LocalNotificationPreferencesStore(storage).read();
    expect(reloaded.jobAlerts, isFalse);
    expect(reloaded.coachTips, isFalse);
    expect(reloaded.applicationUpdates, isTrue);
  });

  test('controller persists each toggle', () async {
    final storage = await _storage();
    final container = ProviderContainer(
      overrides: [localStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);

    final ctrl = container.read(notificationsControllerProvider.notifier);
    await ctrl.setJobAlerts(value: false);
    await ctrl.setMaster(value: false);

    expect(container.read(notificationsControllerProvider).jobAlerts, isFalse);
    expect(container.read(notificationsControllerProvider).master, isFalse);

    // Persisted: a brand-new store instance reads the same values back.
    final persisted = LocalNotificationPreferencesStore(storage).read();
    expect(persisted.jobAlerts, isFalse);
    expect(persisted.master, isFalse);
  });
}
