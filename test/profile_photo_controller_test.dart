import 'dart:typed_data';

import 'package:careerbridge/core/services/user_profile/in_memory_user_profile_repository.dart';
import 'package:careerbridge/core/services/user_profile/profile_image_storage.dart';
import 'package:careerbridge/core/services/user_profile/user_profile_repository.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/profile/application/profile_photo_controller.dart';
import 'package:careerbridge/features/profile/domain/profile_failure.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

/// In-memory [ProfileImageStorage]: returns [url] (or null to simulate failure)
/// and records the last upload.
class FakeProfileImageStorage implements ProfileImageStorage {
  FakeProfileImageStorage(this.url);
  final String? url;
  Uint8List? lastBytes;

  @override
  Future<String?> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    lastBytes = bytes;
    return url;
  }
}

const _user = AppUser(uid: 'u1', method: AuthMethod.email, displayName: 'Sarah');

ProviderContainer _container({
  required String? uploadUrl,
  AppUser? user = _user,
  InMemoryUserProfileRepository? repo,
}) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider
          .overrideWithValue(FakeAuthRepository(user: user)),
      profileImageStorageProvider
          .overrideWithValue(FakeProfileImageStorage(uploadUrl)),
      userProfileRepositoryProvider
          .overrideWithValue(repo ?? InMemoryUserProfileRepository()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  final bytes = Uint8List.fromList([1, 2, 3, 4]);

  test('uploads, then persists the URL to the profile and the auth identity',
      () async {
    final repo = InMemoryUserProfileRepository();
    final c = _container(uploadUrl: 'https://img/p.jpg', repo: repo);
    await c
        .read(profilePhotoControllerProvider.notifier)
        .uploadBytes(bytes, fileName: 'me.png');

    expect(c.read(profilePhotoControllerProvider).status, PhotoStatus.idle);
    final stored = await repo.fetchProfile('u1');
    expect(stored?.photoUrl, 'https://img/p.jpg');

    final fake = c.read(authRepositoryProvider) as FakeAuthRepository;
    expect(fake.lastProfileUpdate?.photoUrl, 'https://img/p.jpg');
  });

  test('a null upload URL surfaces a photo-upload failure', () async {
    final c = _container(uploadUrl: null);
    await c.read(profilePhotoControllerProvider.notifier).uploadBytes(bytes);
    final state = c.read(profilePhotoControllerProvider);
    expect(state.status, PhotoStatus.error);
    expect(state.failure, ProfileFailure.photoUploadFailed);
  });

  test('signed-out users cannot upload', () async {
    final c = _container(uploadUrl: 'https://x', user: null);
    await c.read(profilePhotoControllerProvider.notifier).uploadBytes(bytes);
    final state = c.read(profilePhotoControllerProvider);
    expect(state.status, PhotoStatus.error);
    expect(state.failure, ProfileFailure.notSignedIn);
  });
}
