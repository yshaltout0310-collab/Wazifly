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

/// Routes the user onward after a successful sign-in and ensures their Firestore
/// profile exists. Sends them to role selection if they haven't chosen one yet,
/// otherwise straight home.
///
/// Centralizing this keeps every auth entry point (email, Google, phone)
/// consistent.
void goAfterAuth(BuildContext context, WidgetRef ref) {
  // Create/refresh the profile document (no-op until Firebase is configured).
  final user = ref.read(authRepositoryProvider).currentUser;
  if (user != null) {
    unawaited(ref.read(userProfileRepositoryProvider).ensureProfile(user));
  }

  final type = ref.read(userTypeControllerProvider);
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
