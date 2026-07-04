import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/services/storage/local_storage_service.dart';
import '../../../core/services/storage/storage_keys.dart';
import '../domain/notification_preferences.dart';

/// Persistence seam for [NotificationPreferences].
///
/// The default [LocalNotificationPreferencesStore] keeps them in
/// SharedPreferences (like the other app preferences). Swap the binding to sync
/// with a remote backend / FCM topics later — **no feature changes**.
abstract interface class NotificationPreferencesStore {
  NotificationPreferences read();
  Future<void> write(NotificationPreferences prefs);
}

/// Local, device-scoped store backed by [LocalStorageService].
class LocalNotificationPreferencesStore
    implements NotificationPreferencesStore {
  LocalNotificationPreferencesStore(this._storage);

  final LocalStorageService _storage;

  @override
  NotificationPreferences read() => NotificationPreferences(
        master: _storage.getBool(StorageKeys.notificationsEnabled,
            defaultValue: true),
        jobAlerts:
            _storage.getBool(StorageKeys.notifyJobAlerts, defaultValue: true),
        applicationUpdates: _storage.getBool(
            StorageKeys.notifyApplicationUpdates,
            defaultValue: true),
        coachTips:
            _storage.getBool(StorageKeys.notifyCoachTips, defaultValue: true),
      );

  @override
  Future<void> write(NotificationPreferences prefs) async {
    await _storage.setBool(StorageKeys.notificationsEnabled,
        value: prefs.master);
    await _storage.setBool(StorageKeys.notifyJobAlerts, value: prefs.jobAlerts);
    await _storage.setBool(StorageKeys.notifyApplicationUpdates,
        value: prefs.applicationUpdates);
    await _storage.setBool(StorageKeys.notifyCoachTips, value: prefs.coachTips);
  }
}

final notificationPreferencesStoreProvider =
    Provider<NotificationPreferencesStore>(
  (ref) => LocalNotificationPreferencesStore(ref.watch(localStorageProvider)),
);
