import 'package:equatable/equatable.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/user_profile/profile_image_storage.dart';
import '../../../core/services/user_profile/user_profile_repository.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/profile_failure.dart';

enum PhotoStatus { idle, working, error }

class ProfilePhotoState extends Equatable {
  const ProfilePhotoState({this.status = PhotoStatus.idle, this.failure});

  final PhotoStatus status;
  final ProfileFailure? failure;

  bool get isWorking => status == PhotoStatus.working;

  @override
  List<Object?> get props => [status, failure];
}

/// Picks an image (via `file_selector` — no new plugin), uploads it through the
/// [ProfileImageStorage] seam, then persists the URL to both the profile
/// document and the auth identity.
class ProfilePhotoController extends StateNotifier<ProfilePhotoState> {
  ProfilePhotoController(this._ref) : super(const ProfilePhotoState());

  final Ref _ref;

  Future<void> pickAndUpload() async {
    if (state.isWorking) return;

    final user = _ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      state = const ProfilePhotoState(
          status: PhotoStatus.error, failure: ProfileFailure.notSignedIn);
      return;
    }

    final XFile? file;
    try {
      file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Images',
            extensions: ['jpg', 'jpeg', 'png', 'webp'],
            mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
            uniformTypeIdentifiers: ['public.image'],
          ),
        ],
      );
    } catch (e) {
      debugPrint('[ProfilePhoto] pick failed: $e');
      state = const ProfilePhotoState(
          status: PhotoStatus.error, failure: ProfileFailure.unknown);
      return;
    }

    if (file == null) return; // cancelled — leave state untouched

    final bytes = await file.readAsBytes();
    await uploadBytes(bytes, fileName: file.name);
  }

  /// Uploads [bytes] as the current user's photo and persists the resulting URL
  /// to both the profile document and the auth identity. Split out from the
  /// picker so it is unit-testable without a platform file dialog.
  @visibleForTesting
  Future<void> uploadBytes(Uint8List bytes, {String fileName = 'photo.jpg'}) async {
    final user = _ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      state = const ProfilePhotoState(
          status: PhotoStatus.error, failure: ProfileFailure.notSignedIn);
      return;
    }

    state = const ProfilePhotoState(status: PhotoStatus.working);
    try {
      final url = await _ref
          .read(profileImageStorageProvider)
          .uploadProfilePhoto(
            uid: user.uid,
            bytes: bytes,
            contentType: _contentType(fileName),
          );
      if (url == null) {
        state = const ProfilePhotoState(
            status: PhotoStatus.error,
            failure: ProfileFailure.photoUploadFailed);
        return;
      }
      await _ref.read(userProfileRepositoryProvider).setPhotoUrl(user.uid, url);
      await _ref.read(authRepositoryProvider).updateProfile(photoUrl: url);
      state = const ProfilePhotoState();
    } catch (e) {
      debugPrint('[ProfilePhoto] upload failed: $e');
      state = const ProfilePhotoState(
          status: PhotoStatus.error, failure: ProfileFailure.photoUploadFailed);
    }
  }

  String _contentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

final profilePhotoControllerProvider =
    StateNotifierProvider<ProfilePhotoController, ProfilePhotoState>(
  ProfilePhotoController.new,
);
