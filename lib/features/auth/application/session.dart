import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/cv_repository/last_selected_cv.dart';
import '../../security/application/biometric_settings_controller.dart';
import '../../user_type/application/user_type_controller.dart';
import 'auth_providers.dart';

/// Ends the session **and** clears every piece of device-local state that
/// belongs to the user who was signed in.
///
/// There are three places a user can be signed out — Settings, the
/// verify-email gate's "use another account", and a failed biometric unlock —
/// and they each used to clean up differently. Only Settings cleared anything;
/// the other two left the previous account's role, biometric preference and
/// CV-picker memory in place for whoever signed in next. On a shared device
/// that is how one account ends up wearing another's state.
///
/// What is cleared is deliberately **only** what is scoped to a user:
///
///  * the cached role — otherwise the next account inherits this one's
///    dashboard, or a brand-new user skips role selection entirely;
///  * the biometric preference — a credential-adjacent setting that must not
///    survive into another account (a normal sign-in re-enables it);
///  * the remembered apply-with CV — it points at a CV the next user cannot
///    even read.
///
/// Device preferences — theme, language, country, onboarding-completed — are
/// deliberately **kept**: they belong to the device, not the account, and
/// wiping them would restart onboarding for whoever signs in next.
///
/// Every step is awaited so the caller can navigate knowing the slate is
/// clean, and the sign-out itself happens first: if a later step throws, the
/// user is still signed out rather than left in a half-ended session.
Future<void> signOutAndClearUserScopedState(WidgetRef ref) async {
  await ref.read(authRepositoryProvider).signOut();
  await ref.read(userTypeControllerProvider.notifier).clear();
  await ref.read(biometricSettingsControllerProvider.notifier).reset();
  await ref.read(lastSelectedCvProvider.notifier).clear();
}
