import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/app_user.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/auth_repository.dart';

/// The production [AuthRepository], backed by Firebase Authentication.
///
/// Overridden in tests with a fake (the real repository needs a live Firebase
/// app).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Reactive auth state for routing and UI.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});
