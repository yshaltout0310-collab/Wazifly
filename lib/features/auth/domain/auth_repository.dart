import '../../../shared/models/app_user.dart';
import 'auth_exception.dart';

/// Phone-verification callbacks.
typedef PhoneCodeSent = void Function(String verificationId);
typedef PhoneVerificationFailed = void Function(AuthException error);
typedef PhoneAutoVerified = void Function(AppUser user);

/// Authentication contract.
///
/// The app depends only on this interface; the concrete implementation
/// ([FirebaseAuthRepository], or [UnconfiguredAuthRepository] until credentials
/// exist) is selected at runtime. This keeps feature code backend-agnostic.
abstract interface class AuthRepository {
  /// Emits the current user (or null) and every subsequent change.
  Stream<AppUser?> authStateChanges();

  /// Synchronously available current user, if any.
  AppUser? get currentUser;

  // --- Email/password ---
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset(String email);

  // --- Google ---
  Future<AppUser> signInWithGoogle();

  // --- Phone / OTP ---
  /// Starts verification. On platforms that support it, [onAutoVerified] may
  /// fire and complete sign-in automatically; otherwise [onCodeSent] provides
  /// the verification id used by [confirmSmsCode].
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneCodeSent onCodeSent,
    required PhoneVerificationFailed onFailed,
    PhoneAutoVerified? onAutoVerified,
  });

  Future<AppUser> confirmSmsCode({
    required String verificationId,
    required String smsCode,
  });

  // --- Session ---
  Future<void> signOut();
}
