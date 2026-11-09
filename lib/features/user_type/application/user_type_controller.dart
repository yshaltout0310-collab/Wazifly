import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/services/storage/storage_keys.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/user_type.dart';

/// Holds and persists the selected [UserType] (Job Seeker / Employer).
///
/// The persisted cache is a single device-global slot, so it records **which
/// uid it belongs to** and is ignored when that does not match the signed-in
/// user. Without that, a second account on the same device inherits the first
/// account's role — the employer dashboard for a job seeker, or a brand-new
/// user skipping role selection entirely.
class UserTypeController extends StateNotifier<UserType?> {
  UserTypeController(this._ref) : super(_cachedRoleFor(_ref));

  final Ref _ref;

  /// The cached role, but only if it was cached for the user signed in now.
  ///
  /// Returns null when nobody is signed in, when the cache has no recorded
  /// owner (written before this was introduced — one authoritative Firestore
  /// read then re-caches it correctly), or when it belongs to someone else.
  static UserType? _cachedRoleFor(Ref ref) {
    final storage = ref.read(localStorageProvider);
    final owner = storage.getString(StorageKeys.userTypeOwnerUid);
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null || owner == null || owner != uid) return null;
    return UserType.fromName(storage.getString(StorageKeys.userType));
  }

  /// The uid any write should be attributed to.
  String? get _currentUid => _ref.read(authRepositoryProvider).currentUser?.uid;

  Future<void> select(UserType type) async {
    state = type;
    await _write(type);
  }

  /// Persists [type] together with its owning uid, or clears both when there
  /// is no signed-in user to attribute it to.
  Future<void> _write(UserType type) async {
    final storage = _ref.read(localStorageProvider);
    final uid = _currentUid;
    if (uid == null) {
      await storage.remove(StorageKeys.userType);
      await storage.remove(StorageKeys.userTypeOwnerUid);
      return;
    }
    await storage.setString(StorageKeys.userType, type.name);
    await storage.setString(StorageKeys.userTypeOwnerUid, uid);
  }

  /// Reconciles the local cache with an authoritative value (the per-user role
  /// stored in Firestore). Unlike [select] this is not a user action — it keeps
  /// the device-local cache pointing at the *current* user's role so the splash
  /// fast-path and Settings display stay correct after an account switch.
  ///
  /// [type] `null` clears the cache (the user hasn't chosen a role yet).
  Future<void> sync(UserType? type) async {
    state = type;
    if (type == null) {
      await clear();
      return;
    }
    await _write(type);
  }

  Future<void> clear() async {
    state = null;
    final storage = _ref.read(localStorageProvider);
    await storage.remove(StorageKeys.userType);
    await storage.remove(StorageKeys.userTypeOwnerUid);
  }
}

final userTypeControllerProvider =
    StateNotifierProvider<UserTypeController, UserType?>(
  UserTypeController.new,
);
