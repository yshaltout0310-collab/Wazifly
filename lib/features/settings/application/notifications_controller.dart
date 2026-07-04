import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/notification_preferences.dart';
import 'notification_preferences_store.dart';

/// Holds and persists the user's [NotificationPreferences] (master toggle +
/// granular categories).
///
/// When Firebase Messaging is configured, this is also where topic
/// subscription/unsubscription would be wired (prepared for a later phase).
class NotificationsController extends StateNotifier<NotificationPreferences> {
  NotificationsController(this._store) : super(_store.read());

  final NotificationPreferencesStore _store;

  Future<void> _update(NotificationPreferences next) async {
    state = next;
    await _store.write(next);
  }

  Future<void> setMaster({required bool value}) =>
      _update(state.copyWith(master: value));

  Future<void> setJobAlerts({required bool value}) =>
      _update(state.copyWith(jobAlerts: value));

  Future<void> setApplicationUpdates({required bool value}) =>
      _update(state.copyWith(applicationUpdates: value));

  Future<void> setCoachTips({required bool value}) =>
      _update(state.copyWith(coachTips: value));
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, NotificationPreferences>(
  (ref) =>
      NotificationsController(ref.watch(notificationPreferencesStoreProvider)),
);
