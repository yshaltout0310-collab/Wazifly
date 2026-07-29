import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/route_names.dart';
import '../../../core/services/company/company_repository.dart';
import '../../../core/services/user_profile/user_profile_repository.dart';
import '../../user_type/application/user_type_controller.dart';
import '../../user_type/domain/user_type.dart';
import '../application/auth_providers.dart';

/// Resolves the signed-in user's role. **Firestore (`users/{uid}.userType`) is
/// the source of truth**; the local [UserTypeController] is only a per-user
/// cache that this keeps in sync.
///
/// [trustCache] — when `true` (a returning session on this device), a non-null
/// cached role is used directly: it was reconciled for *this* user at their last
/// sign-in, so this stays fast and works offline. When `false` (a fresh sign-in
/// or account switch), the cache is ignored and the role is read from Firestore,
/// so a different — or brand-new — user can never inherit a role that a previous
/// user left in the device-global cache. This is the bug that made new users skip
/// role selection and land straight in the Job Seeker flow.
Future<UserType?> _resolveUserType(
  WidgetRef ref, {
  required bool trustCache,
}) async {
  final user = ref.read(authRepositoryProvider).currentUser;
  if (user == null) return ref.read(userTypeControllerProvider);

  if (trustCache) {
    final cached = ref.read(userTypeControllerProvider);
    if (cached != null) return cached;
  }

  // Authoritative per-user role from Firestore (null until they pick one).
  final profile =
      await ref.read(userProfileRepositoryProvider).fetchProfile(user.uid);
  final remote = profile?.userType;
  // Reconcile the device-local cache with the authoritative value.
  await ref.read(userTypeControllerProvider.notifier).sync(remote);
  return remote;
}

/// Routes the user onward after a successful sign-in and ensures their Firestore
/// profile exists. Sends them to role selection if they haven't chosen a role
/// yet (checked against Firestore, not the device-local cache), otherwise
/// straight to the role's home.
///
/// Centralizing this keeps every auth entry point consistent.
Future<void> goAfterAuth(BuildContext context, WidgetRef ref) async {
  // Create/refresh the profile document (no-op until Firebase is configured).
  final user = ref.read(authRepositoryProvider).currentUser;
  if (user != null) {
    await ref.read(userProfileRepositoryProvider).ensureProfile(user);
  }

  // Fresh sign-in: never trust the device-local cache — read the role from
  // Firestore so a new account always reaches role selection.
  final type = await _resolveUserType(ref, trustCache: false);
  if (!context.mounted) return;

  if (type == null) {
    context.goNamed(RouteNames.userType);
    return;
  }
  if (type == UserType.employer) {
    // Ensure the company document exists for returning employers (idempotent).
    if (user != null) {
      unawaited(ref.read(companyRepositoryProvider).ensureCompany(
            user.uid,
            email: user.email,
            name: user.displayName,
          ));
    }
    context.goNamed(RouteNames.employerHome);
  } else {
    context.goNamed(RouteNames.home);
  }
}

/// Routes a user who ALREADY has a valid session to their role home. Used by the
/// splash and the biometric app-lock screen (which unlock an existing session);
/// unlike [goAfterAuth] it does not re-create the profile/company docs.
///
/// Uses the per-user cache when present (fast, offline-safe) and falls back to
/// the authoritative Firestore role otherwise, so a user with no stored role is
/// sent to role selection rather than defaulted into a flow.
Future<void> goToRoleHome(BuildContext context, WidgetRef ref) async {
  final type = await _resolveUserType(ref, trustCache: true);
  if (!context.mounted) return;
  context.goNamed(switch (type) {
    null => RouteNames.userType,
    UserType.employer => RouteNames.employerHome,
    UserType.jobSeeker => RouteNames.home,
  });
}
