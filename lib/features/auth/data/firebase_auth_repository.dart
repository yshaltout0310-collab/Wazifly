// Hide Firebase's phone callback typedefs to avoid clashing with our own
// (defined in auth_repository.dart); we pass inline closures regardless.
import 'package:firebase_auth/firebase_auth.dart'
    hide PhoneCodeSent, PhoneVerificationFailed;
import 'package:flutter/foundation.dart';

import '../../../shared/models/app_user.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_repository.dart';

/// Firebase-backed [AuthRepository] — the production authentication path.
///
/// Google sign-in uses [FirebaseAuth.signInWithProvider] (OAuth via a Custom
/// Tab) so no extra `google_sign_in` dependency is needed. All failures are
/// normalized to [AuthException] with a stable [AuthErrorCode].
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository([FirebaseAuth? auth])
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  AppUser? _map(User? user, {AuthMethod? method}) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      method: method ?? _inferMethod(user),
      email: user.email,
      phoneNumber: user.phoneNumber,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  AuthMethod _inferMethod(User user) {
    final providers = user.providerData.map((p) => p.providerId);
    if (providers.contains('google.com')) return AuthMethod.google;
    if (providers.contains('phone')) return AuthMethod.phone;
    return AuthMethod.email;
  }

  @override
  Stream<AppUser?> authStateChanges() =>
      _auth.authStateChanges().map((u) => _map(u));

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        return _map(cred.user, method: AuthMethod.email)!;
      });

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        return _map(cred.user, method: AuthMethod.email)!;
      });

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<AppUser> signInWithGoogle() async {
    // Not routed through [_guard]: the federated `signInWithProvider` handshake
    // can fail with a *non*-FirebaseAuthException (a PlatformException from a
    // missing OAuth client / unregistered SHA-1, or a cancelled Custom Tab),
    // which _guard would rethrow raw as an opaque error. Here we log the exact
    // cause for on-device diagnosis and always surface a typed [AuthException].
    try {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      final cred = await _auth.signInWithProvider(provider);
      return _map(cred.user, method: AuthMethod.google)!;
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] Google sign-in FirebaseAuthException: '
          'code=${e.code} message=${e.message}');
      throw AuthException.fromFirebaseCode(e.code, e.message);
    } catch (e) {
      // Raw type + message go to logcat (visible via `adb logcat`) so a config
      // failure is diagnosable on a real device — see docs/GOOGLE_SIGNIN_SETUP.md.
      debugPrint('[Auth] Google sign-in failed (${e.runtimeType}): $e');
      throw AuthException(_classifyGoogleError(e), e.toString());
    }
  }

  /// Classifies a non-[FirebaseAuthException] Google sign-in failure from its
  /// message: a user-dismissed Custom Tab → [AuthErrorCode.cancelled]; a
  /// connectivity failure → [AuthErrorCode.network]; anything else is treated as
  /// a provider/OAuth **configuration** problem (the common real-device cause:
  /// the Google provider isn't enabled / no SHA-1 registered / empty
  /// `oauth_client` in `google-services.json`).
  static AuthErrorCode _classifyGoogleError(Object e) {
    final m = e.toString().toLowerCase();
    if (m.contains('cancel') || m.contains('dismiss')) {
      return AuthErrorCode.cancelled;
    }
    if (m.contains('network') ||
        m.contains('timeout') ||
        m.contains('timed out') ||
        m.contains('unreachable')) {
      return AuthErrorCode.network;
    }
    return AuthErrorCode.configurationError;
  }

  @override
  Future<void> verifyPhoneForLink({
    required String phoneNumber,
    required PhoneCodeSent onCodeSent,
    required PhoneVerificationFailed onFailed,
    PhoneLinked? onAutoLinked,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      verificationCompleted: (PhoneAuthCredential credential) async {
        if (onAutoLinked == null) return;
        try {
          // LINK to the existing account (never signInWithCredential — that
          // would create/switch to a phone-only account).
          final user = _auth.currentUser;
          if (user == null) return;
          final cred = await user.linkWithCredential(credential);
          final linked = _map(cred.user);
          if (linked != null) onAutoLinked(linked);
        } catch (_) {/* fall back to manual entry */}
      },
      verificationFailed: (FirebaseAuthException e) =>
          onFailed(AuthException.fromFirebaseCode(e.code, e.message)),
      codeSent: (String verificationId, int? resendToken) =>
          onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  @override
  Future<AppUser> confirmAndLinkSmsCode({
    required String verificationId,
    required String smsCode,
  }) =>
      _guard(() async {
        final user = _auth.currentUser;
        if (user == null) throw const AuthException(AuthErrorCode.userNotFound);
        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode.trim(),
        );
        final cred = await user.linkWithCredential(credential);
        // Preserve the original sign-in method; the account is merely
        // strengthened with a verified phone number.
        return _map(cred.user)!;
      });

  @override
  Future<void> reauthenticateWithPassword(String password) => _guard(() async {
        final user = _auth.currentUser;
        final email = user?.email;
        if (user == null || email == null) {
          throw const AuthException(AuthErrorCode.userNotFound);
        }
        final credential =
            EmailAuthProvider.credential(email: email, password: password);
        await user.reauthenticateWithCredential(credential);
      });

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _guard(() async {
        final user = _auth.currentUser;
        final email = user?.email;
        if (user == null || email == null) {
          throw const AuthException(AuthErrorCode.userNotFound);
        }
        // Firebase requires a recent login to change a password; re-authenticate
        // with the current credentials first.
        final credential = EmailAuthProvider.credential(
          email: email,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
      });

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) =>
      _guard(() async {
        final user = _auth.currentUser;
        if (user == null) throw const AuthException(AuthErrorCode.userNotFound);
        if (displayName != null) await user.updateDisplayName(displayName);
        if (photoUrl != null) await user.updatePhotoURL(photoUrl);
      });

  @override
  Future<void> signOut() => _auth.signOut();

  /// Normalizes Firebase errors into a typed [AuthException].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseCode(e.code, e.message);
    }
  }
}
