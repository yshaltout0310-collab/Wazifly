import 'dart:async';

import '../../../shared/models/learning_profile.dart';
import 'learning_profile_repository.dart';

/// Session-scoped [LearningProfileRepository] for tests (and any Noop fallback).
/// Re-emits the profile on every change through a broadcast stream, mirroring how
/// a Firestore document `.snapshots()` re-emits.
class InMemoryLearningProfileRepository implements LearningProfileRepository {
  InMemoryLearningProfileRepository({LearningProfile? seed}) {
    if (seed != null) _profiles[seed.uid] = seed;
  }

  final Map<String, LearningProfile> _profiles = {};
  final _controller = StreamController<LearningProfile>.broadcast();

  LearningProfile _get(String uid) =>
      _profiles[uid] ?? LearningProfile.empty(uid);

  @override
  Stream<LearningProfile> watchProfile(String uid) async* {
    yield _get(uid);
    yield* _controller.stream.where((p) => p.uid == uid);
  }

  @override
  Future<LearningProfile> fetchProfile(String uid) async => _get(uid);

  @override
  Future<void> saveProfile(LearningProfile profile) async {
    _profiles[profile.uid] = profile;
    _controller.add(profile);
  }
}
