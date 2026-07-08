/// The user's push-notification permission, as a plain value (no vendor type).
enum NotificationPermission { granted, denied, provisional, notDetermined }

/// A received push message, flattened to plain values so no `firebase_messaging`
/// type crosses the [NotificationService] boundary.
class PushMessage {
  const PushMessage({
    this.messageId,
    this.title,
    this.body,
    this.data = const {},
  });

  final String? messageId;
  final String? title;
  final String? body;
  final Map<String, String> data;
}

/// Provider-agnostic push-notification lifecycle (the single Firebase Messaging
/// boundary). Only `FirebaseNotificationService` imports `firebase_messaging`;
/// swap the backend by rebinding `notificationServiceProvider`.
///
/// Every method is **best-effort and non-throwing** — notification failures must
/// never affect app functionality (the M1 telemetry principle). No UI is wired
/// this milestone; [onMessageOpened] is exposed so a future milestone can
/// deep-link via the existing router with no refactor.
abstract interface class NotificationService {
  /// Requests permission, retrieves the token, and attaches listeners.
  Future<void> initialize();

  /// Requests the OS notification permission and returns the resulting status.
  Future<NotificationPermission> requestPermission();

  /// The current registration token (or null when unavailable).
  Future<String?> getToken();

  /// The last-known token without a network call (null until fetched).
  String? get cachedToken;

  /// Emits whenever the registration token is rotated.
  Stream<String> get onTokenRefresh;

  /// Deletes the current registration token (e.g. on sign-out).
  Future<void> deleteToken();

  /// Messages received while the app is in the foreground.
  Stream<PushMessage> get onMessage;

  /// Fired when the user taps a notification that opened the app.
  Stream<PushMessage> get onMessageOpened;
}
