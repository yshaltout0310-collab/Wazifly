import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/services/biometric/biometric_service.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/widgets/auth_error.dart';
import '../../settings/presentation/widgets/settings_tile.dart';
import '../application/biometric_settings_controller.dart';

/// Account security hub: biometric login + phone verification + trusted device.
class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  Future<void> _toggleBiometric(
    BuildContext context,
    WidgetRef ref, {
    required bool enable,
  }) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(biometricSettingsControllerProvider.notifier);
    if (!enable) {
      await controller.disable();
      if (context.mounted) showAuthSnack(context, l10n.biometricDisabledSnack);
      return;
    }
    final result = await controller.enable(reason: l10n.biometricReasonEnable);
    if (!context.mounted) return;
    if (result == BiometricAuthResult.success) {
      showAuthSnack(context, l10n.biometricEnabledSnack);
    } else if (result != BiometricAuthResult.unavailable) {
      showAuthSnack(context, l10n.biometricFailed, isError: true);
    }
  }

  Future<void> _removeTrustedDevice(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(l10n.securityRemoveDeviceTitle),
        content: Text(l10n.securityRemoveDeviceBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.securityRemoveDevice),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(biometricSettingsControllerProvider.notifier).disable();
    if (context.mounted) {
      showAuthSnack(context, l10n.securityDeviceRemovedSnack);
    }
  }

  String _maskPhone(String phone) {
    if (phone.length <= 4) return phone;
    final last4 = phone.substring(phone.length - 4);
    return '•••• •••• $last4';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final biometric = ref.watch(biometricSettingsControllerProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    final phone = user?.phoneNumber;
    final hasPhone = phone != null && phone.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.securityTitle)),
      body: SafeArea(
        child: ResponsiveCenter(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.horizontalGutter,
              AppSpacing.md,
              context.horizontalGutter,
              AppSpacing.xl,
            ),
            children: [
              SettingsSection(
                title: l10n.securityBiometricSection,
                children: [
                  // Available → a working toggle. Not-enrolled → disabled with a
                  // hint. Unavailable → hidden (the app never blocks access).
                  if (biometric.isAvailable)
                    SettingsTile(
                      icon: Icons.fingerprint_rounded,
                      title: l10n.securityBiometricTitle,
                      subtitle: l10n.securityBiometricSubtitle,
                      trailing: Switch(
                        value: biometric.enabled,
                        onChanged: (v) =>
                            _toggleBiometric(context, ref, enable: v),
                      ),
                    )
                  else if (biometric.isNotEnrolled)
                    SettingsTile(
                      icon: Icons.fingerprint_rounded,
                      title: l10n.securityBiometricTitle,
                      subtitle: l10n.securityBiometricNotEnrolled,
                      trailing: const Switch(value: false, onChanged: null),
                    )
                  else
                    SettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: l10n.securityBiometricTitle,
                      subtitle: l10n.securityBiometricUnavailable,
                    ),
                  if (biometric.enabled)
                    SettingsTile(
                      icon: Icons.devices_rounded,
                      title: l10n.securityRemoveDevice,
                      subtitle: l10n.securityRemoveDeviceSubtitle,
                      destructive: true,
                      onTap: () => _removeTrustedDevice(context, ref),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SettingsSection(
                title: l10n.securityPhoneSection,
                children: [
                  SettingsTile(
                    icon: hasPhone
                        ? Icons.verified_rounded
                        : Icons.phone_android_rounded,
                    title: l10n.securityVerifyPhoneTitle,
                    subtitle: hasPhone
                        ? '${l10n.securityPhoneVerified} · ${_maskPhone(phone)}'
                        : l10n.securityPhoneNotVerified,
                    trailing:
                        hasPhone ? null : const Icon(Icons.chevron_right_rounded),
                    onTap: hasPhone
                        ? null
                        : () => context.pushNamed(RouteNames.phoneVerify),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
