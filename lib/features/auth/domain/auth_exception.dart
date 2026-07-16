/// Stable, backend-agnostic auth error codes the UI can localize.
enum AuthErrorCode {
  invalidCredentials,
  emailInUse,
  userNotFound,
  weakPassword,
  network,
  tooManyRequests,
  invalidPhone,
  invalidOtp,
  operationNotAllowed,
  cancelled,

  /// The operation needs a recent sign-in (Firebase `requires-recent-login`) —
  /// the UI prompts the user to re-authenticate first.
  requiresRecentLogin,

  /// The phone number is already linked to a different account.
  phoneAlreadyInUse,

  /// The current account already has a phone number linked.
  credentialAlreadyLinked,

  /// A sign-in provider/backend is not fully configured for this app (e.g. a
  /// Firebase internal/authorization error). Surfaced with a clearer message
  /// than [unknown] so the failure isn't opaque.
  configurationError,

  unknown,
}

/// User-facing authentication error carrying a stable [code] so the
/// presentation layer can show a localized message (and an optional raw
/// message for logging/diagnostics).
class AuthException implements Exception {
  const AuthException(this.code, [this.rawMessage]);

  final AuthErrorCode code;
  final String? rawMessage;

  /// Maps a FirebaseAuthException `code` string to a stable [AuthErrorCode].
  factory AuthException.fromFirebaseCode(String code, [String? message]) {
    final mapped = switch (code) {
      'invalid-credential' ||
      'wrong-password' ||
      'invalid-login-credentials' =>
        AuthErrorCode.invalidCredentials,
      'email-already-in-use' => AuthErrorCode.emailInUse,
      'user-not-found' => AuthErrorCode.userNotFound,
      'weak-password' => AuthErrorCode.weakPassword,
      'network-request-failed' => AuthErrorCode.network,
      'too-many-requests' => AuthErrorCode.tooManyRequests,
      'invalid-phone-number' => AuthErrorCode.invalidPhone,
      'invalid-verification-code' ||
      'invalid-verification-id' =>
        AuthErrorCode.invalidOtp,
      'operation-not-allowed' => AuthErrorCode.operationNotAllowed,
      'requires-recent-login' => AuthErrorCode.requiresRecentLogin,
      'credential-already-in-use' ||
      'account-exists-with-different-credential' =>
        AuthErrorCode.phoneAlreadyInUse,
      'provider-already-linked' => AuthErrorCode.credentialAlreadyLinked,
      'web-context-canceled' ||
      'user-cancelled' ||
      'cancelled' ||
      'canceled' =>
        AuthErrorCode.cancelled,
      // A sign-in method that isn't fully configured on the backend typically
      // surfaces as one of these — map them to a clear "configuration" message
      // instead of the opaque generic error.
      'internal-error' ||
      'admin-restricted-operation' ||
      'app-not-authorized' ||
      'invalid-oauth-client-id' ||
      'invalid-oauth-provider' ||
      'missing-client-identifier' ||
      'unauthorized-domain' =>
        AuthErrorCode.configurationError,
      _ => AuthErrorCode.unknown,
    };
    return AuthException(mapped, message);
  }

  @override
  String toString() => 'AuthException(${code.name}): $rawMessage';
}
