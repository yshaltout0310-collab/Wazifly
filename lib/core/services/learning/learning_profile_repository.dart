import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_providers.dart';
import '../../../shared/models/learning_profile.dart';
import 'firestore_learning_profile_repository.dart';

/// Owns the seeker's learning interests at `users/{uid}/learning/interests`.
///
/// A core service (like `UserProfileRepository`/`CvRepository`) so the learning
/// feature depends on **core**, never on another feature. Transitions are pure
/// [LearningProfile] methods computed by the controller, then persisted via
/// [saveProfile]. Swap the binding (Firestore ↔ in-memory) with **no feature
/// changes**.
abstract interface class LearningProfileRepository {
  /// Emits the owner's learning profile and re-emits on every change — maps 1:1
  /// to a Firestore document `.snapshots()`.
  Stream<LearningProfile> watchProfile(String uid);

  /// One-shot read (empty profile when none exists yet).
  Future<LearningProfile> fetchProfile(String uid);

  /// Persists the whole (small) document with a merge.
  Future<void> saveProfile(LearningProfile profile);
}

/// The app-wide learning-profile repository. Firestore in production; overridden
/// with an in-memory fake in tests. Swap this one binding to change the backend.
final learningProfileRepositoryProvider = Provider<LearningProfileRepository>(
  (ref) => FirestoreLearningProfileRepository(),
);

/// Reactive view of the signed-in seeker's learning profile.
final learningProfileProvider = StreamProvider<LearningProfile>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return Stream<LearningProfile>.value(LearningProfile.empty(''));
  }
  return ref.watch(learningProfileRepositoryProvider).watchProfile(user.uid);
});
