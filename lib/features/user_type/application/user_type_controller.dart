import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/services/storage/storage_keys.dart';
import '../domain/user_type.dart';

/// Holds and persists the selected [UserType] (Job Seeker / Employer).
class UserTypeController extends StateNotifier<UserType?> {
  UserTypeController(this._ref)
      : super(UserType.fromName(
          _ref.read(localStorageProvider).getString(StorageKeys.userType),
        ));

  final Ref _ref;

  Future<void> select(UserType type) async {
    state = type;
    await _ref
        .read(localStorageProvider)
        .setString(StorageKeys.userType, type.name);
  }

  Future<void> clear() async {
    state = null;
    await _ref.read(localStorageProvider).remove(StorageKeys.userType);
  }
}

final userTypeControllerProvider =
    StateNotifierProvider<UserTypeController, UserType?>(
  UserTypeController.new,
);
