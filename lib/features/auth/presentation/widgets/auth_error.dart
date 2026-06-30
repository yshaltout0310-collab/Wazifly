import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../domain/auth_exception.dart';

/// Resolves any thrown auth error into a friendly, localized message.
String localizedAuthMessage(AppLocalizations l10n, Object error) {
  final code = error is AuthException ? error.code : AuthErrorCode.unknown;
  return switch (code) {
    AuthErrorCode.invalidCredentials => l10n.errInvalidCredentials,
    AuthErrorCode.emailInUse => l10n.errEmailInUse,
    AuthErrorCode.userNotFound => l10n.errUserNotFound,
    AuthErrorCode.weakPassword => l10n.errWeakPassword,
    AuthErrorCode.network => l10n.errNetwork,
    AuthErrorCode.tooManyRequests => l10n.errTooManyRequests,
    AuthErrorCode.invalidPhone => l10n.errInvalidPhone,
    AuthErrorCode.invalidOtp => l10n.errInvalidOtpCode,
    AuthErrorCode.operationNotAllowed => l10n.errOperationNotAllowed,
    AuthErrorCode.cancelled => l10n.errCancelled,
    AuthErrorCode.unknown => l10n.authFailed,
  };
}

/// Shows a polished error snackbar for an auth failure.
void showAuthError(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);
  showAuthSnack(context, localizedAuthMessage(l10n, error), isError: true);
}

/// Branded snackbar used for both errors and confirmations.
void showAuthSnack(BuildContext context, String message,
    {bool isError = false}) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? AppColors.error : scheme.inverseSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: AppColors.white,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
}
