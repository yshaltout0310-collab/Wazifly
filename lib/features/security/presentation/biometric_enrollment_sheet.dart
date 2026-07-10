import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/services/biometric/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../auth/presentation/widgets/auth_error.dart';
import '../application/biometric_settings_controller.dart';

/// After a fresh sign-in, offers to enable biometric login — but only once
/// (a "Not Now" is remembered) and only when the device supports it. Never
/// blocks the sign-in flow; callers `await` it then continue routing.
Future<void> maybeOfferBiometricEnrollment(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = ref.read(biometricSettingsControllerProvider.notifier);
  if (!await controller.shouldOfferEnrollment()) return;
  if (!context.mounted) return;

  final enable = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _BiometricEnrollmentSheet(),
  );
  if (!context.mounted) return;

  if (enable == true) {
    final l10n = AppLocalizations.of(context);
    final result = await controller.enable(reason: l10n.biometricReasonEnable);
    if (!context.mounted) return;
    if (result == BiometricAuthResult.success) {
      showAuthSnack(context, l10n.biometricEnabledSnack);
    } else if (result != BiometricAuthResult.unavailable) {
      showAuthSnack(context, l10n.biometricFailed, isError: true);
    }
  } else {
    // "Not Now" (or dismissed) — remember it so we don't ask every sign-in.
    await controller.declineEnrollment();
  }
}

class _BiometricEnrollmentSheet extends StatelessWidget {
  const _BiometricEnrollmentSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fingerprint_rounded,
                  size: 40, color: AppColors.emerald),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.biometricPromptTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.biometricPromptBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.lock_open_rounded),
              label: Text(l10n.biometricEnable),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.biometricNotNow),
            ),
          ],
        ),
      ),
    );
  }
}
