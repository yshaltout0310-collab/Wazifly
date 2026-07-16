import '../../../shared/models/app_user.dart';
import 'auth_exception.dart';

/// Phone-verification callbacks.
typedef PhoneCodeSent = void Function(String verificationId);
typedef PhoneVerificationFailed = void Function(AuthException error);

/// Fired when the platform auto-retrieves the SMS code and the phone is linked
/// to the current account without manual entry (Android instant verification).
typedef PhoneLinked = void Function(AppUser user);

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

  // --- Email verification ---
  /// Sends (or re-sends) a Firebase verification email to the signed-in user.
  /// No-op if there is no current user. Throws [AuthException] on failure (e.g.
  /// `too-many-requests` when re-sent too often).
  Future<void> sendEmailVerification();

  /// Reloads the current user from Firebase and returns whether their email is
  /// now verified. Used by the verify-email gate's "I've verified" action, since
  /// `emailVerified` only refreshes on `reload()` / re-sign-in. Returns false if
  /// there is no current user.
  Future<bool> reloadEmailVerified();

  // --- Phone / OTP (verification-by-linking; strengthens an existing account) ---
  /// Starts phone verification in order to **link** the number to the currently
  /// signed-in account (never a phone-only sign-in). On platforms that support
  /// it, [onAutoLinked] may fire and complete linking automatically; otherwise
  /// [onCodeSent] provides the verification id used by [confirmAndLinkSmsCode].
  Future<void> verifyPhoneForLink({
    required String phoneNumber,
    required PhoneCodeSent onCodeSent,
    required PhoneVerificationFailed onFailed,
    PhoneLinked? onAutoLinked,
  });

  /// Links the verified phone credential to the current account and returns the
  /// updated user (now carrying [AppUser.phoneNumber]). Requires a signed-in
  /// user; throws [AuthException] on failure (e.g. wrong code → invalidOtp,
  /// number in use → phoneAlreadyInUse, stale login → requiresRecentLogin).
  Future<AppUser> confirmAndLinkSmsCode({
    required String verificationId,
    required String smsCode,
  });

  /// Re-authenticates the current email/password user with [password]. Used to
  /// clear a `requires-recent-login` state before a sensitive operation.
  Future<void> reauthenticateWithPassword(String password);

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
