import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_providers.dart';
import '../../../features/user_type/domain/user_type.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_profile.dart';
import 'firestore_user_profile_repository.dart';

/// Reads/writes the extended `users/{uid}` profile document.
///
/// Feature code depends only on this interface; the concrete implementation is
/// injected via [userProfileRepositoryProvider]. Swap the binding for a
/// different backend (or a fake in tests) with **no feature changes** — the
/// same seam pattern used by the applications/saved-jobs/chat stores.
abstract interface class UserProfileRepository {
  /// Emits the profile (or null) and every subsequent change — maps 1:1 to a
  /// Firestore document `.snapshots()` stream.
  Stream<UserProfile?> watchProfile(String uid);

  /// One-shot read of the current profile, if any.
  Future<UserProfile?> fetchProfile(String uid);

  /// Merges the user-editable fields into the profile document.
  Future<void> saveProfile(UserProfile profile);

  /// Creates the profile on first sign-in, or refreshes identity fields on
  /// subsequent sign-ins. Safe to call after every successful auth.
  ///
  /// **Returns the stored profile** (null when there was none, or when the
  /// backend is unavailable). It has to read the document anyway to decide
  /// create-vs-refresh, so handing that result back spares every caller a
  /// second, identical read: `goAfterAuth` used to call this and then
  /// `fetchProfile` to re-read the very document it had just written, three
  /// sequential round trips before the first navigation.
  ///
  /// The returned profile reflects state *before* this call's identity write.
  /// That is deliberate and sufficient: the identity fields are the caller's
  /// own [AppUser], and the field callers actually need from storage — the
  /// role — is never written here.
  Future<UserProfile?> ensureProfile(AppUser user);

  /// Persists the chosen role.
  Future<void> setUserType(String uid, UserType type);

  /// Persists a new profile-photo download URL.
  Future<void> setPhotoUrl(String uid, String url);
}

/// The app-wide profile repository. Backed by Firestore in production and
/// overridden with an in-memory fake in tests. Swap this one binding to change
/// the backend.
final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => FirestoreUserProfileRepository(),
);

/// Reactive view of the signed-in user's extended profile.
///
/// Tracks the authenticated uid and pipes the repository's document stream, so
/// edits (name, skills, photo, …) re-render every consumer automatically.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<UserProfile?>.value(null);
  return ref.watch(userProfileRepositoryProvider).watchProfile(user.uid);
});
