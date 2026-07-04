import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/user_profile/user_profile_repository.dart';
import '../../../shared/models/user_profile.dart';
import '../../auth/application/auth_providers.dart';

/// The signed-in user's effective profile: the stored document merged with the
/// auth identity as a fallback (so a freshly created / not-yet-synced doc still
/// reflects the name & photo from Firebase Auth). Null when signed out.
final currentUserProfileProvider = Provider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  final stored = ref.watch(userProfileProvider).valueOrNull;
  final base = stored ?? UserProfile.empty(user.uid);
  return base.copyWith(
    displayName: base.displayName ?? user.displayName,
    photoUrl: base.photoUrl ?? user.photoUrl,
  );
});

/// Profile completion as a percentage `[0, 100]` (0 when signed out).
final profileCompletionProvider = Provider<int>((ref) {
  return ref.watch(currentUserProfileProvider)?.completionPercent ?? 0;
});
