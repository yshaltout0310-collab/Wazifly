import 'package:careerbridge/features/auth/domain/auth_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthException.fromFirebaseCode', () {
    test('maps link/reauth Firebase codes to stable enum values', () {
      expect(AuthException.fromFirebaseCode('requires-recent-login').code,
          AuthErrorCode.requiresRecentLogin);
      expect(AuthException.fromFirebaseCode('credential-already-in-use').code,
          AuthErrorCode.phoneAlreadyInUse);
      expect(
          AuthException.fromFirebaseCode(
                  'account-exists-with-different-credential')
              .code,
          AuthErrorCode.phoneAlreadyInUse);
      expect(AuthException.fromFirebaseCode('provider-already-linked').code,
          AuthErrorCode.credentialAlreadyLinked);
      expect(AuthException.fromFirebaseCode('invalid-verification-id').code,
          AuthErrorCode.invalidOtp);
    });

    test('preserves existing mappings', () {
      expect(AuthException.fromFirebaseCode('wrong-password').code,
          AuthErrorCode.invalidCredentials);
      expect(AuthException.fromFirebaseCode('something-unknown').code,
          AuthErrorCode.unknown);
    });
  });
}
