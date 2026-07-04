import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/user_profile/user_profile_repository.dart';
import '../../../shared/models/user_profile.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/profile_failure.dart';

enum ProfileEditStatus { idle, saving, success, error }

class ProfileEditState extends Equatable {
  const ProfileEditState({this.status = ProfileEditStatus.idle, this.failure});

  final ProfileEditStatus status;
  final ProfileFailure? failure;

  bool get isSaving => status == ProfileEditStatus.saving;

  @override
  List<Object?> get props => [status, failure];
}

/// Saves edits to the extended profile and keeps the Firebase Auth identity
/// (display name) in sync. Backend-agnostic — depends only on the repository +
/// auth interfaces.
class ProfileEditController extends StateNotifier<ProfileEditState> {
  ProfileEditController(this._ref) : super(const ProfileEditState());

  final Ref _ref;

  /// Persists [edited] for the signed-in user. Returns true on success.
  Future<bool> save(UserProfile edited) async {
    final user = _ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      state = const ProfileEditState(
          status: ProfileEditStatus.error, failure: ProfileFailure.notSignedIn);
      return false;
    }

    state = const ProfileEditState(status: ProfileEditStatus.saving);
    try {
      final profile = edited.copyWith(uid: user.uid);
      await _ref.read(userProfileRepositoryProvider).saveProfile(profile);
      // Mirror the display name onto the auth record so greetings/avatars that
      // read the identity stay consistent.
      if (profile.displayName != null && profile.displayName!.isNotEmpty) {
        await _ref
            .read(authRepositoryProvider)
            .updateProfile(displayName: profile.displayName);
      }
      state = const ProfileEditState(status: ProfileEditStatus.success);
      return true;
    } catch (e) {
      debugPrint('[ProfileEdit] save failed: $e');
      state = const ProfileEditState(
          status: ProfileEditStatus.error, failure: ProfileFailure.saveFailed);
      return false;
    }
  }
}

final profileEditControllerProvider =
    StateNotifierProvider<ProfileEditController, ProfileEditState>(
  ProfileEditController.new,
);
