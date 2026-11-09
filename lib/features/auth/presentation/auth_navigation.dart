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

/// Resolves the role for a session that **already exists** (splash, or a
/// biometric app-lock unlock). **Firestore (`users/{uid}.userType`) is the
/// source of truth**; the local [UserTypeController] is a per-user cache this
/// keeps in sync.
///
/// Prefers the cache when present: it was reconciled for *this* user at their
/// last sign-in, so the splash path stays fast and works offline. Falls back to
/// the authoritative Firestore role, so a session with no cached role reaches
/// role selection rather than being defaulted into a flow.
///
/// A **fresh** sign-in does not come through here. [goAfterAuth] reconciles the
/// cache from the profile `ensureProfile` already read, so a different — or
/// brand-new — user can never inherit a role a previous user left in the
/// device-global cache. (That inheritance was the bug that sent new users
/// straight into the Job Seeker flow, skipping role selection.)
Future<UserType?> _resolveUserType(WidgetRef ref) async {
  final user = ref.read(authRepositoryProvider).currentUser;
  if (user == null) return ref.read(userTypeControllerProvider);

  final cached = ref.read(userTypeControllerProvider);
  if (cached != null) return cached;

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
  final user = ref.read(authRepositoryProvider).currentUser;

  final UserType? type;
  if (user == null) {
    type = ref.read(userTypeControllerProvider);
  } else {
    // One read, not three. `ensureProfile` creates/refreshes the profile
    // document and hands back what was stored, so the authoritative role comes
    // from the read it already performed.
    //
    // This path used to await `ensureProfile` (a get, then a set) and then
    // `_resolveUserType(trustCache: false)`, whose `fetchProfile` issued a
    // THIRD round trip to re-read the document just written — all sequential,
    // all before the first navigation, which is what made signing in feel slow.
    final profile =
        await ref.read(userProfileRepositoryProvider).ensureProfile(user);
    type = profile?.userType;
    // Fresh sign-in: the device-local cache is never trusted, it is reconciled
    // *to* the authoritative value, so a different — or brand-new — user can
    // never inherit a role a previous user left in the device-global cache.
    await ref.read(userTypeControllerProvider.notifier).sync(type);
  }
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
  final type = await _resolveUserType(ref);
  if (!context.mounted) return;
  context.goNamed(switch (type) {
    null => RouteNames.userType,
    UserType.employer => RouteNames.employerHome,
    UserType.jobSeeker => RouteNames.home,
  });
}
