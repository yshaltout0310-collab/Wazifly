import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/biometric/biometric_providers.dart';
import '../../../core/services/biometric/biometric_service.dart';
import '../../../core/services/secure_store/secure_keys.dart';
import '../../../core/services/secure_store/secure_store.dart';
import '../../../core/services/secure_store/secure_store_provider.dart';

class BiometricSettingsState extends Equatable {
  const BiometricSettingsState({
    this.capability = BiometricCapability.unavailable,
    this.enabled = false,
    this.loaded = false,
  });

  /// What the device can do right now.
  final BiometricCapability capability;

  /// Whether the user has turned biometric login on (persisted, secure).
  final bool enabled;

  /// True once the async load has completed (the splash gate waits on this).
  final bool loaded;

  /// Biometrics can be offered/enabled only when hardware + an enrolled
  /// credential are present.
  bool get isAvailable => capability == BiometricCapability.available;

  /// Hardware exists but nothing is enrolled — show a disabled option + hint.
  bool get isNotEnrolled => capability == BiometricCapability.notEnrolled;

  /// The launch gate is active only when enabled AND currently usable.
  bool get gateActive => enabled && isAvailable;

  BiometricSettingsState copyWith({
    BiometricCapability? capability,
    bool? enabled,
    bool? loaded,
  }) =>
      BiometricSettingsState(
        capability: capability ?? this.capability,
        enabled: enabled ?? this.enabled,
        loaded: loaded ?? this.loaded,
      );

  @override
  List<Object?> get props => [capability, enabled, loaded];
}

/// Owns the biometric-login preference and the device capability.
///
/// Stores ONLY the preference + a trusted-device marker in [SecureStore] — never
/// passwords or session tokens. The gate it drives sits in front of the already-
/// persisted Firebase session.
class BiometricSettingsController
    extends StateNotifier<BiometricSettingsState> {
  BiometricSettingsController(this._ref)
      : super(const BiometricSettingsState()) {
    _load();
  }

  final Ref _ref;

  BiometricService get _bio => _ref.read(biometricServiceProvider);
  SecureStore get _store => _ref.read(secureStoreProvider);

  Future<void> _load() async {
    final capability = await _bio.capability();
    final enabled = await _store.readBool(SecureKeys.biometricEnabled);
    if (!mounted) return;
    state = state.copyWith(
        capability: capability, enabled: enabled, loaded: true);
  }

  /// Ensures the async load finished, returning the settled state. Used by the
  /// splash gate before it decides whether to show the lock screen.
  Future<BiometricSettingsState> ensureLoaded() async {
    if (state.loaded) return state;
    await _load();
    return state;
  }

  /// Refreshes the capability (e.g. after returning from system settings).
  Future<void> refreshCapability() async {
    final capability = await _bio.capability();
    if (mounted) state = state.copyWith(capability: capability);
  }

  /// Whether to prompt to enable after a fresh sign-in: supported, not already
  /// enabled, and the user hasn't tapped "Not Now".
  Future<bool> shouldOfferEnrollment() async {
    final capability = await _bio.capability();
    if (capability != BiometricCapability.available) return false;
    if (await _store.readBool(SecureKeys.biometricEnabled)) return false;
    return !(await _store.readBool(SecureKeys.biometricPromptDeclined));
  }

  /// Remembers a "Not Now" so the prompt isn't shown after every sign-in.
  Future<void> declineEnrollment() =>
      _store.writeBool(SecureKeys.biometricPromptDeclined, value: true);

  /// Enables biometric login after a successful biometric confirmation. Returns
  /// the auth result so the caller can message a failure.
  Future<BiometricAuthResult> enable({required String reason}) async {
    final result = await _bio.authenticate(reason: reason);
    if (result != BiometricAuthResult.success) return result;
    await _store.writeBool(SecureKeys.biometricEnabled, value: true);
    await _store.write(
        SecureKeys.trustedDeviceId,
        DateTime.now().microsecondsSinceEpoch.toRadixString(16));
    await _store.delete(SecureKeys.biometricPromptDeclined);
    if (mounted) state = state.copyWith(enabled: true);
    return result;
  }

  /// Turns biometric login off and forgets the trusted device.
  Future<void> disable() async {
    await _store.delete(SecureKeys.biometricEnabled);
    await _store.delete(SecureKeys.trustedDeviceId);
    if (mounted) state = state.copyWith(enabled: false);
  }

  /// Clears ALL biometric state. Called on logout and after a sensitive
  /// credential change, so a normal sign-in is required before it can be
  /// re-enabled.
  Future<void> reset() async {
    await _store.delete(SecureKeys.biometricEnabled);
    await _store.delete(SecureKeys.trustedDeviceId);
    await _store.delete(SecureKeys.biometricPromptDeclined);
    if (mounted) state = state.copyWith(enabled: false);
  }
}

final biometricSettingsControllerProvider = StateNotifierProvider<
    BiometricSettingsController, BiometricSettingsState>(
  BiometricSettingsController.new,
);
