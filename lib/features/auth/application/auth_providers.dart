import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firebase/firebase_service.dart';
import '../../../shared/models/app_user.dart';
import '../data/firebase_auth_repository.dart';
import '../data/unconfigured_auth_repository.dart';
import '../domain/auth_repository.dart';

/// True when real Firebase credentials are not present yet, so authentication
/// is disabled (the app still runs). Drives the "connect Firebase" notice.
final firebaseNotConfiguredProvider = Provider<bool>(
  (ref) => !FirebaseService.instance.isReady,
);

/// The production [AuthRepository]: Firebase when ready, otherwise a clean
/// unconfigured stub (no demo/mock sign-in).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseService.instance.isReady
      ? FirebaseAuthRepository()
      : UnconfiguredAuthRepository();
});

/// Reactive auth state for routing and UI.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});
