import 'package:careerbridge/core/services/biometric/biometric_service.dart';

/// Configurable [BiometricService] for tests.
class FakeBiometricService implements BiometricService {
  FakeBiometricService({
    this.cap = BiometricCapability.available,
    this.authResult = BiometricAuthResult.success,
  });

  BiometricCapability cap;
  BiometricAuthResult authResult;
  int authCalls = 0;

  @override
  Future<BiometricCapability> capability() async => cap;

  @override
  Future<BiometricAuthResult> authenticate({required String reason}) async {
    authCalls++;
    return authResult;
  }
}
