// Hide Firebase's phone callback typedefs to avoid clashing with our own
// (defined in auth_repository.dart); we pass inline closures regardless.
import 'package:firebase_auth/firebase_auth.dart'
    hide PhoneCodeSent, PhoneVerificationFailed;

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
  Future<AppUser> signInWithGoogle() => _guard(() async {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        final cred = await _auth.signInWithProvider(provider);
        return _map(cred.user, method: AuthMethod.google)!;
      });

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneCodeSent onCodeSent,
    required PhoneVerificationFailed onFailed,
    PhoneAutoVerified? onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      verificationCompleted: (PhoneAuthCredential credential) async {
        if (onAutoVerified == null) return;
        try {
          final cred = await _auth.signInWithCredential(credential);
          final user = _map(cred.user, method: AuthMethod.phone);
          if (user != null) onAutoVerified(user);
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
  Future<AppUser> confirmSmsCode({
    required String verificationId,
    required String smsCode,
  }) =>
      _guard(() async {
        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode.trim(),
        );
        final cred = await _auth.signInWithCredential(credential);
        return _map(cred.user, method: AuthMethod.phone)!;
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
