import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/auth/domain/auth_exception.dart';
import 'package:careerbridge/features/profile/application/change_password_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

ProviderContainer _container({Object? changePasswordError}) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(changePasswordError: changePasswordError),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('rejects empty fields', () async {
    final c = _container();
    final ctrl = c.read(changePasswordControllerProvider.notifier);
    final ok = await ctrl.submit(
        currentPassword: '', newPassword: '', confirmPassword: '');
    expect(ok, isFalse);
    expect(c.read(changePasswordControllerProvider).failure,
        ChangePasswordFailure.emptyFields);
  });

  test('rejects a too-short new password', () async {
    final c = _container();
    final ctrl = c.read(changePasswordControllerProvider.notifier);
    final ok = await ctrl.submit(
        currentPassword: 'oldpass', newPassword: '123', confirmPassword: '123');
    expect(ok, isFalse);
    expect(c.read(changePasswordControllerProvider).failure,
        ChangePasswordFailure.tooShort);
  });

  test('rejects a confirmation mismatch', () async {
    final c = _container();
    final ctrl = c.read(changePasswordControllerProvider.notifier);
    final ok = await ctrl.submit(
        currentPassword: 'oldpass',
        newPassword: 'newpass1',
        confirmPassword: 'newpass2');
    expect(ok, isFalse);
    expect(c.read(changePasswordControllerProvider).failure,
        ChangePasswordFailure.mismatch);
  });

  test('succeeds and forwards credentials to the repository', () async {
    final c = _container();
    final ctrl = c.read(changePasswordControllerProvider.notifier);
    final ok = await ctrl.submit(
        currentPassword: 'oldpass',
        newPassword: 'newpass1',
        confirmPassword: 'newpass1');
    expect(ok, isTrue);
    expect(c.read(changePasswordControllerProvider).status,
        ChangePasswordStatus.success);

    final fake = c.read(authRepositoryProvider) as FakeAuthRepository;
    expect(fake.lastPasswordChange?.current, 'oldpass');
    expect(fake.lastPasswordChange?.next, 'newpass1');
  });

  test('surfaces a backend auth error', () async {
    final c = _container(
      changePasswordError:
          const AuthException(AuthErrorCode.invalidCredentials),
    );
    final ctrl = c.read(changePasswordControllerProvider.notifier);
    final ok = await ctrl.submit(
        currentPassword: 'wrong',
        newPassword: 'newpass1',
        confirmPassword: 'newpass1');
    expect(ok, isFalse);
    final state = c.read(changePasswordControllerProvider);
    expect(state.status, ChangePasswordStatus.error);
    expect(state.authError, isA<AuthException>());
    expect((state.authError as AuthException).code,
        AuthErrorCode.invalidCredentials);
  });
}
