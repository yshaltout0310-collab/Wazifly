import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/cv_repository/last_selected_cv.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/core/services/storage/storage_keys.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/user_type/application/user_type_controller.dart';
import 'package:careerbridge/features/user_type/domain/user_type.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth.dart';

/// Multi-account hygiene on a shared device.
///
/// The persisted role is a single device-global slot. Without an owner recorded
/// beside it, a second account inherits the first account's role — a job seeker
/// landing on the employer dashboard, or a brand-new user skipping role
/// selection entirely because a cached role answered for them.

const _seeker = AppUser(uid: 'u_seeker', method: AuthMethod.email);
const _employer = AppUser(uid: 'u_employer', method: AuthMethod.email);

Future<LocalStorageService> _storageWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return LocalStorageService.create();
}

ProviderContainer _container(LocalStorageService storage, AppUser? user) {
  final container = ProviderContainer(overrides: [
    localStorageProvider.overrideWithValue(storage),
    authRepositoryProvider.overrideWithValue(FakeAuthRepository(user: user)),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('the cached role is scoped to its owner', () {
    test('is used when it belongs to the signed-in user', () async {
      final storage = await _storageWith({
        StorageKeys.userType: 'employer',
        StorageKeys.userTypeOwnerUid: 'u_employer',
      });
      final container = _container(storage, _employer);

      expect(container.read(userTypeControllerProvider), UserType.employer);
    });

    test('is ignored when it belongs to someone else', () async {
      // The exact leak: an employer signed in here last, now a seeker signs in.
      final storage = await _storageWith({
        StorageKeys.userType: 'employer',
        StorageKeys.userTypeOwnerUid: 'u_employer',
      });
      final container = _container(storage, _seeker);

      expect(
        container.read(userTypeControllerProvider),
        isNull,
        reason: 'a role cached for another account must never answer for this '
            'one — null sends them to role selection, which is correct',
      );
    });

    test('is ignored when nobody is signed in', () async {
      final storage = await _storageWith({
        StorageKeys.userType: 'employer',
        StorageKeys.userTypeOwnerUid: 'u_employer',
      });
      final container = _container(storage, null);

      expect(container.read(userTypeControllerProvider), isNull);
    });

    test('an ownerless cache from an older build is ignored, not trusted',
        () async {
      // Migration: installs that cached a role before the owner key existed.
      // One authoritative Firestore read re-caches it correctly.
      final storage = await _storageWith({StorageKeys.userType: 'employer'});
      final container = _container(storage, _employer);

      expect(container.read(userTypeControllerProvider), isNull);
    });
  });

  group('writes record the owner', () {
    test('select stores the role and the uid together', () async {
      final storage = await _storageWith({});
      final container = _container(storage, _employer);

      await container
          .read(userTypeControllerProvider.notifier)
          .select(UserType.employer);

      expect(storage.getString(StorageKeys.userType), 'employer');
      expect(storage.getString(StorageKeys.userTypeOwnerUid), 'u_employer');
    });

    test('sync stores the owner too, so the next launch can trust it',
        () async {
      final storage = await _storageWith({});
      final container = _container(storage, _seeker);

      await container
          .read(userTypeControllerProvider.notifier)
          .sync(UserType.jobSeeker);

      expect(storage.getString(StorageKeys.userTypeOwnerUid), 'u_seeker');
    });

    test('nothing is cached when there is no user to attribute it to',
        () async {
      final storage = await _storageWith({});
      final container = _container(storage, null);

      await container
          .read(userTypeControllerProvider.notifier)
          .select(UserType.employer);

      expect(storage.getString(StorageKeys.userType), isNull);
      expect(storage.getString(StorageKeys.userTypeOwnerUid), isNull);
    });

    test('clear removes both keys', () async {
      final storage = await _storageWith({
        StorageKeys.userType: 'employer',
        StorageKeys.userTypeOwnerUid: 'u_employer',
      });
      final container = _container(storage, _employer);

      await container.read(userTypeControllerProvider.notifier).clear();

      expect(storage.getString(StorageKeys.userType), isNull);
      expect(storage.getString(StorageKeys.userTypeOwnerUid), isNull);
    });

    test('sync(null) clears the owner as well', () async {
      final storage = await _storageWith({
        StorageKeys.userType: 'employer',
        StorageKeys.userTypeOwnerUid: 'u_employer',
      });
      final container = _container(storage, _employer);

      await container.read(userTypeControllerProvider.notifier).sync(null);

      expect(storage.getString(StorageKeys.userTypeOwnerUid), isNull,
          reason: 'leaving the owner behind would re-arm the leak');
    });
  });

  group('device preferences survive an account change', () {
    test('theme, language, country and onboarding are not user-scoped',
        () async {
      final storage = await _storageWith({
        StorageKeys.userType: 'employer',
        StorageKeys.userTypeOwnerUid: 'u_employer',
        StorageKeys.themeMode: 'dark',
        StorageKeys.languageCode: 'ar',
        StorageKeys.onboardingCompleted: true,
      });
      final container = _container(storage, _employer);

      await container.read(userTypeControllerProvider.notifier).clear();
      await container.read(lastSelectedCvProvider.notifier).clear();

      // Wiping these would restart onboarding for whoever signs in next, which
      // is a worse failure than the leak being fixed.
      expect(storage.getString(StorageKeys.themeMode), 'dark');
      expect(storage.getString(StorageKeys.languageCode), 'ar');
      expect(storage.getBool(StorageKeys.onboardingCompleted), isTrue);
    });
  });

  group('the remembered apply-with CV is user-scoped', () {
    test('clearing it removes the stored id', () async {
      final storage =
          await _storageWith({StorageKeys.lastSelectedCvId: 'cv_from_prev'});
      final container = _container(storage, _seeker);

      expect(container.read(lastSelectedCvProvider), 'cv_from_prev');

      await container.read(lastSelectedCvProvider.notifier).clear();

      expect(container.read(lastSelectedCvProvider), isNull);
      expect(storage.getString(StorageKeys.lastSelectedCvId), isNull,
          reason: 'it points at a CV the next account cannot even read');
    });
  });
}
