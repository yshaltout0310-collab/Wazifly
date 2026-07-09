/// Provider-agnostic Firebase App Check (the single `firebase_app_check`
/// boundary). App Check attests that requests come from a genuine, unmodified
/// app instance, so the backend (Firestore / Storage / AI Logic) can reject
/// traffic from scrapers and tampered clients.
///
/// Only `FirebaseAppCheckService` imports the plugin; swap the backend by
/// rebinding `appCheckServiceProvider`. Every method is **best-effort and
/// non-throwing** — attestation must never block startup or a user action (the
/// M1 telemetry principle, applied to security). If activation fails the app
/// keeps running unattested; the failure is recorded via the crash reporter +
/// security audit log by the bootstrap.
abstract interface class AppCheckService {
  /// Activates App Check. On debug builds this uses the **debug provider**
  /// (a token you register in the Firebase Console); on release it uses the
  /// platform attestation provider (Play Integrity on Android). Returns whether
  /// activation succeeded — never throws.
  Future<bool> activate();

  /// Returns a current App Check token (forcing a refresh when [forceRefresh]),
  /// or null when unavailable / unconfigured. Never throws.
  Future<String?> getToken({bool forceRefresh = false});
}
