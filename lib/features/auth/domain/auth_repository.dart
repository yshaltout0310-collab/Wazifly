import '../../../shared/models/app_user.dart';
import 'auth_exception.dart';

/// Phone-verification callbacks.
typedef PhoneCodeSent = void Function(String verificationId);
typedef PhoneVerificationFailed = void Function(AuthException error);
typedef PhoneAutoVerified = void Function(AppUser user);

/// Authentication contract.
///
/// The app depends only on this interface; the concrete implementation
/// ([FirebaseAuthRepository]) is injected via Riverpod, and a fake is swapped in
/// for tests. This keeps feature code backend-agnostic.
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

  // --- Account management ---
  /// Re-authenticates with [currentPassword] and sets [newPassword]. Only valid
  /// for email/password accounts. Throws [AuthException] on failure (e.g. a
  /// wrong current password maps to [AuthErrorCode.invalidCredentials]).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Updates the signed-in user's Firebase Auth display name and/or photo URL so
  /// the auth identity stays in sync with the extended profile.
  Future<void> updateProfile({String? displayName, String? photoUrl});

  // --- Session ---
  Future<void> signOut();
}
