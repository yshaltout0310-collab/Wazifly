import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';

enum ChangePasswordStatus { idle, submitting, success, error }

/// Local (pre-submit) validation reasons, distinct from backend auth errors.
enum ChangePasswordFailure { emptyFields, tooShort, mismatch }

class ChangePasswordState extends Equatable {
  const ChangePasswordState({
    this.status = ChangePasswordStatus.idle,
    this.failure,
    this.authError,
  });

  final ChangePasswordStatus status;

  /// Set when local validation fails (screen shows a localized message).
  final ChangePasswordFailure? failure;

  /// The thrown backend error, resolved via `localizedAuthMessage`.
  final Object? authError;

  bool get isSubmitting => status == ChangePasswordStatus.submitting;

  @override
  List<Object?> get props => [status, failure, authError];
}

/// Validates and applies a password change through the auth interface
/// (re-authentication is handled inside the repository).
class ChangePasswordController extends StateNotifier<ChangePasswordState> {
  ChangePasswordController(this._ref) : super(const ChangePasswordState());

  final Ref _ref;

  /// Firebase's minimum password length.
  static const int minLength = 6;

  Future<bool> submit({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      state = const ChangePasswordState(
          status: ChangePasswordStatus.error,
          failure: ChangePasswordFailure.emptyFields);
      return false;
    }
    if (newPassword.length < minLength) {
      state = const ChangePasswordState(
          status: ChangePasswordStatus.error,
          failure: ChangePasswordFailure.tooShort);
      return false;
    }
    if (newPassword != confirmPassword) {
      state = const ChangePasswordState(
          status: ChangePasswordStatus.error,
          failure: ChangePasswordFailure.mismatch);
      return false;
    }

    state = const ChangePasswordState(status: ChangePasswordStatus.submitting);
    try {
      await _ref.read(authRepositoryProvider).changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      state = const ChangePasswordState(status: ChangePasswordStatus.success);
      return true;
    } catch (e) {
      debugPrint('[ChangePassword] failed: $e');
      state = ChangePasswordState(
          status: ChangePasswordStatus.error, authError: e);
      return false;
    }
  }
}

final changePasswordControllerProvider =
    StateNotifierProvider<ChangePasswordController, ChangePasswordState>(
  ChangePasswordController.new,
);
