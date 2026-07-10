import 'biometric_service.dart';

/// A [BiometricService] that reports biometrics as unavailable and never
/// authenticates. Used in tests / on platforms without support, so the biometric
/// feature simply never appears and never blocks the app.
class NoopBiometricService implements BiometricService {
  const NoopBiometricService();

  @override
  Future<BiometricCapability> capability() async =>
      BiometricCapability.unavailable;

  @override
  Future<BiometricAuthResult> authenticate({required String reason}) async =>
      BiometricAuthResult.unavailable;
}
