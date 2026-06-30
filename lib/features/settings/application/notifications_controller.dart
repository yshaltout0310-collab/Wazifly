import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/services/storage/storage_keys.dart';

/// Holds and persists the push-notifications opt-in.
///
/// When Firebase Messaging is configured, this is also where token
/// subscription/unsubscription would be wired (prepared for a later phase).
class NotificationsController extends StateNotifier<bool> {
  NotificationsController(this._ref)
      : super(_ref.read(localStorageProvider).getBool(
          StorageKeys.notificationsEnabled,
          defaultValue: true,
        ));

  final Ref _ref;

  Future<void> setEnabled({required bool value}) async {
    state = value;
    await _ref.read(localStorageProvider).setBool(
          StorageKeys.notificationsEnabled,
          value: value,
        );
  }
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, bool>(
  NotificationsController.new,
);
