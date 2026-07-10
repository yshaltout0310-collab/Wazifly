import 'package:careerbridge/core/services/biometric/biometric_providers.dart';
import 'package:careerbridge/core/services/biometric/biometric_service.dart';
import 'package:careerbridge/core/services/secure_store/in_memory_secure_store.dart';
import 'package:careerbridge/core/services/secure_store/secure_keys.dart';
import 'package:careerbridge/core/services/secure_store/secure_store_provider.dart';
import 'package:careerbridge/features/security/application/biometric_settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_biometric.dart';

void main() {
  late FakeBiometricService bio;
  late InMemorySecureStore store;

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [
      biometricServiceProvider.overrideWithValue(bio),
      secureStoreProvider.overrideWithValue(store),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    bio = FakeBiometricService();
    store = InMemorySecureStore();
  });

  test('loads capability + disabled state by default', () async {
    final c = makeContainer();
    final state = await c
        .read(biometricSettingsControllerProvider.notifier)
        .ensureLoaded();
    expect(state.loaded, isTrue);
    expect(state.isAvailable, isTrue);
    expect(state.enabled, isFalse);
    expect(state.gateActive, isFalse);
  });

  test('shouldOfferEnrollment true when available, not enabled, not declined',
      () async {
    final c = makeContainer();
    final ctrl = c.read(biometricSettingsControllerProvider.notifier);
    expect(await ctrl.shouldOfferEnrollment(), isTrue);
  });

  test('declineEnrollment is remembered (no re-prompt)', () async {
    final c = makeContainer();
    final ctrl = c.read(biometricSettingsControllerProvider.notifier);
    await ctrl.declineEnrollment();
    expect(await ctrl.shouldOfferEnrollment(), isFalse);
    expect(
        await store.readBool(SecureKeys.biometricPromptDeclined), isTrue);
  });

  test('no offer when biometrics unavailable', () async {
    bio.cap = BiometricCapability.unavailable;
    final c = makeContainer();
    final ctrl = c.read(biometricSettingsControllerProvider.notifier);
    expect(await ctrl.shouldOfferEnrollment(), isFalse);
    final state = await ctrl.ensureLoaded();
    expect(state.isAvailable, isFalse);
  });

  test('enable persists + sets trusted device + clears declined on success',
      () async {
    final c = makeContainer();
    final ctrl = c.read(biometricSettingsControllerProvider.notifier);
    await ctrl.declineEnrollment();
    final result = await ctrl.enable(reason: 'r');
    expect(result, BiometricAuthResult.success);
    expect(c.read(biometricSettingsControllerProvider).enabled, isTrue);
    expect(await store.readBool(SecureKeys.biometricEnabled), isTrue);
    expect(await store.read(SecureKeys.trustedDeviceId), isNotNull);
    expect(
        await store.readBool(SecureKeys.biometricPromptDeclined), isFalse);
  });

  test('enable does nothing when biometric auth fails', () async {
    bio.authResult = BiometricAuthResult.failed;
    final c = makeContainer();
    final ctrl = c.read(biometricSettingsControllerProvider.notifier);
    final result = await ctrl.enable(reason: 'r');
    expect(result, BiometricAuthResult.failed);
    expect(c.read(biometricSettingsControllerProvider).enabled, isFalse);
    expect(await store.readBool(SecureKeys.biometricEnabled), isFalse);
  });

  test('disable clears the flag + trusted device', () async {
    final c = makeContainer();
    final ctrl = c.read(biometricSettingsControllerProvider.notifier);
    await ctrl.enable(reason: 'r');
    await ctrl.disable();
    expect(c.read(biometricSettingsControllerProvider).enabled, isFalse);
    expect(await store.readBool(SecureKeys.biometricEnabled), isFalse);
    expect(await store.read(SecureKeys.trustedDeviceId), isNull);
  });

  test('reset clears everything (logout / sensitive change)', () async {
    final c = makeContainer();
    final ctrl = c.read(biometricSettingsControllerProvider.notifier);
    await ctrl.enable(reason: 'r');
    await ctrl.declineEnrollment();
    await ctrl.reset();
    expect(await store.readBool(SecureKeys.biometricEnabled), isFalse);
    expect(await store.read(SecureKeys.trustedDeviceId), isNull);
    expect(
        await store.readBool(SecureKeys.biometricPromptDeclined), isFalse);
  });

  test('gateActive only when enabled AND available', () async {
    final c = makeContainer();
    final ctrl = c.read(biometricSettingsControllerProvider.notifier);
    await ctrl.enable(reason: 'r');
    expect(c.read(biometricSettingsControllerProvider).gateActive, isTrue);

    // If biometrics later become unavailable, the gate is no longer active.
    bio.cap = BiometricCapability.unavailable;
    await ctrl.refreshCapability();
    expect(c.read(biometricSettingsControllerProvider).gateActive, isFalse);
  });
}
