import 'dart:async';

import '../../../features/user_type/domain/user_type.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_profile.dart';
import 'user_profile_repository.dart';

/// Session-scoped [UserProfileRepository] for tests and offline runs.
///
/// Holds one profile per uid in memory and re-emits the current value on every
/// change through a per-uid broadcast stream (mirroring Firestore `.snapshots()`).
class InMemoryUserProfileRepository implements UserProfileRepository {
  InMemoryUserProfileRepository({List<UserProfile> seed = const []}) {
    for (final p in seed) {
      _profiles[p.uid] = p;
    }
  }

  final Map<String, UserProfile> _profiles = {};
  final Map<String, StreamController<UserProfile?>> _controllers = {};

  StreamController<UserProfile?> _controllerFor(String uid) =>
      _controllers.putIfAbsent(
        uid,
        () => StreamController<UserProfile?>.broadcast(),
      );

  void _emit(String uid) => _controllerFor(uid).add(_profiles[uid]);

  @override
  Stream<UserProfile?> watchProfile(String uid) async* {
    yield _profiles[uid]; // current value to new listeners
    yield* _controllerFor(uid).stream;
  }

  @override
  Future<UserProfile?> fetchProfile(String uid) async => _profiles[uid];

  @override
  Future<void> saveProfile(UserProfile profile) async {
    _profiles[profile.uid] = profile;
    _emit(profile.uid);
  }

  @override
  Future<void> ensureProfile(AppUser user) async {
    final existing = _profiles[user.uid];
    _profiles[user.uid] = (existing ?? UserProfile.empty(user.uid)).copyWith(
      displayName: user.displayName,
      photoUrl: user.photoUrl,
    );
    _emit(user.uid);
  }

  @override
  Future<void> setUserType(String uid, UserType type) async {
    final base = _profiles[uid] ?? UserProfile.empty(uid);
    _profiles[uid] = base.copyWith(userType: type);
    _emit(uid);
  }

  @override
  Future<void> setPhotoUrl(String uid, String url) async {
    final base = _profiles[uid] ?? UserProfile.empty(uid);
    _profiles[uid] = base.copyWith(photoUrl: url);
    _emit(uid);
  }
}
