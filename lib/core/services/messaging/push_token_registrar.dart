import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persists / clears the device's FCM registration token for the signed-in user.
///
/// **Future-ready seam:** today a no-op that only logs. Rebind to a
/// Firestore-backed implementation writing `users/{uid}/fcmTokens/{token}` to
/// enable targeted / topic pushes — **no feature changes**, and no new Firestore
/// rule this milestone (the existing own-doc `users/{uid}` rule already covers a
/// subcollection when it goes live).
abstract interface class PushTokenRegistrar {
  Future<void> register({required String uid, required String token});
  Future<void> unregister({required String uid, required String token});
}

/// Inert registrar (default): records nothing, just logs. Never throws.
class NoopPushTokenRegistrar implements PushTokenRegistrar {
  const NoopPushTokenRegistrar();

  @override
  Future<void> register({required String uid, required String token}) async {
    final head = token.length > 8 ? token.substring(0, 8) : token;
    debugPrint('[PushToken] register (no-op) uid=$uid token=$head…');
  }

  @override
  Future<void> unregister({required String uid, required String token}) async {
    debugPrint('[PushToken] unregister (no-op) uid=$uid');
  }
}

/// The app-wide token registrar (swap this binding for a Firestore-backed one
/// later — no feature changes).
final pushTokenRegistrarProvider = Provider<PushTokenRegistrar>(
  (ref) => const NoopPushTokenRegistrar(),
);
