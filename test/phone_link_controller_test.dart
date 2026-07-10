import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/auth/application/phone_link_controller.dart';
import 'package:careerbridge/features/auth/domain/auth_exception.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

void main() {
  const user = AppUser(
    uid: 'u1',
    method: AuthMethod.email,
    email: 'a@b.com',
  );

  late FakeAuthRepository repo;

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ]);
    // Keep the autoDispose controller alive for the duration of the test.
    c.listen(phoneLinkControllerProvider, (_, __) {});
    addTearDown(c.dispose);
    return c;
  }

  setUp(() => repo = FakeAuthRepository(user: user));

  test('starts at enterNumber', () {
    final c = makeContainer();
    expect(c.read(phoneLinkControllerProvider).stage,
        PhoneLinkStage.enterNumber);
  });

  test('empty number is rejected locally', () async {
    final c = makeContainer();
    await c.read(phoneLinkControllerProvider.notifier).sendCode('   ');
    final s = c.read(phoneLinkControllerProvider);
    expect(s.localFailure, PhoneLinkFailure.emptyNumber);
    expect(s.stage, PhoneLinkStage.enterNumber);
  });

  test('sendCode advances to enterCode and starts the resend cooldown',
      () async {
    final c = makeContainer();
    await c.read(phoneLinkControllerProvider.notifier).sendCode('+974123456');
    final s = c.read(phoneLinkControllerProvider);
    expect(s.stage, PhoneLinkStage.enterCode);
    expect(s.verificationId, 'test-verification-id');
    expect(s.phoneNumber, '+974123456');
    expect(s.resendSeconds, greaterThan(0));
    expect(s.canResend, isFalse);
  });

  test('a short code is rejected locally', () async {
    final c = makeContainer();
    final notifier = c.read(phoneLinkControllerProvider.notifier);
    await notifier.sendCode('+974123456');
    final ok = await notifier.submitCode('123');
    expect(ok, isFalse);
    expect(c.read(phoneLinkControllerProvider).localFailure,
        PhoneLinkFailure.invalidCode);
  });

  test('valid code links the phone to the existing account', () async {
    final c = makeContainer();
    final notifier = c.read(phoneLinkControllerProvider.notifier);
    await notifier.sendCode('+974123456');
    final ok = await notifier.submitCode('123456');
    expect(ok, isTrue);
    expect(c.read(phoneLinkControllerProvider).stage, PhoneLinkStage.linked);
    // The repository linked (not signed in) — preserving the original account.
    expect(repo.linkedPhone, isNotNull);
  });

  test('a link error returns to enterCode with the error', () async {
    repo = FakeAuthRepository(
      user: user,
      linkPhoneError: const AuthException(AuthErrorCode.invalidOtp),
    );
    final c = makeContainer();
    final notifier = c.read(phoneLinkControllerProvider.notifier);
    await notifier.sendCode('+974123456');
    final ok = await notifier.submitCode('123456');
    expect(ok, isFalse);
    final s = c.read(phoneLinkControllerProvider);
    expect(s.stage, PhoneLinkStage.enterCode);
    expect(s.error, isA<AuthException>());
  });

  test('resend is a no-op while the cooldown is active', () async {
    final c = makeContainer();
    final notifier = c.read(phoneLinkControllerProvider.notifier);
    await notifier.sendCode('+974123456');
    // Cooldown is active immediately after sending.
    expect(c.read(phoneLinkControllerProvider).canResend, isFalse);
    await notifier.resend();
    // Still on the code stage; no crash / no state regression.
    expect(c.read(phoneLinkControllerProvider).stage, PhoneLinkStage.enterCode);
  });
}
