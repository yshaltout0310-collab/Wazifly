import '../../../shared/models/app_user.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_repository.dart';

/// Active when Firebase has no real credentials yet.
///
/// This is NOT a demo/mock — it performs no fake sign-in. It simply reports a
/// signed-out state and fails every action with [AuthErrorCode.notConfigured],
/// so the app launches and the UI can show a friendly "connect Firebase"
/// message. Swapped out automatically once `flutterfire configure` runs.
class UnconfiguredAuthRepository implements AuthRepository {
  static const _err = AuthException(AuthErrorCode.notConfigured);

  @override
  Stream<AppUser?> authStateChanges() => Stream<AppUser?>.value(null);

  @override
  AppUser? get currentUser => null;

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      throw _err;

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
  }) async =>
      throw _err;

  @override
  Future<void> sendPasswordReset(String email) async => throw _err;

  @override
  Future<AppUser> signInWithGoogle() async => throw _err;

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneCodeSent onCodeSent,
    required PhoneVerificationFailed onFailed,
    PhoneAutoVerified? onAutoVerified,
  }) async =>
      onFailed(_err);

  @override
  Future<AppUser> confirmSmsCode({
    required String verificationId,
    required String smsCode,
  }) async =>
      throw _err;

  @override
  Future<void> signOut() async {}
}
