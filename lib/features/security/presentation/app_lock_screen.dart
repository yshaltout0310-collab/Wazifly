import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/services/biometric/biometric_providers.dart';
import '../../../core/services/biometric/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/auth_navigation.dart';
import '../../user_type/application/user_type_controller.dart';
import '../application/biometric_settings_controller.dart';

/// Biometric unlock gate shown at cold launch when a valid Firebase session
/// exists AND biometric login is enabled. Success opens the app immediately;
/// failure/cancel offers "Sign in another way" (a full sign-out → Welcome).
///
/// It never bypasses Firebase — the session is already authenticated; this is a
/// local access gate in front of it.
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  bool _authenticating = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Auto-prompt on entry.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _failed = false;
    });
    final l10n = AppLocalizations.of(context);
    final result = await ref
        .read(biometricServiceProvider)
        .authenticate(reason: l10n.biometricReasonUnlock);
    if (!mounted) return;

    if (result == BiometricAuthResult.success) {
      goToRoleHome(context, ref);
      return;
    }
    setState(() {
      _authenticating = false;
      _failed = true;
    });
  }

  Future<void> _signInAnother() async {
    // Sign out (which disables biometric for the next session) and return to the
    // normal login screen.
    await ref.read(biometricSettingsControllerProvider.notifier).reset();
    await ref.read(authRepositoryProvider).signOut();
    await ref.read(userTypeControllerProvider.notifier).clear();
    if (!mounted) return;
    context.goNamed(RouteNames.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppLogo(size: 88),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.appLockTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _failed ? l10n.appLockFailed : l10n.appLockSubtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: InkWell(
                  onTap: _authenticating ? null : _unlock,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: _authenticating
                        ? const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : const Icon(Icons.fingerprint_rounded,
                            size: 52, color: AppColors.emerald),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_failed)
                FilledButton.icon(
                  onPressed: _authenticating ? null : _unlock,
                  icon: const Icon(Icons.lock_open_rounded),
                  label: Text(l10n.appLockRetry),
                ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _authenticating ? null : _signInAnother,
                child: Text(l10n.appLockSignInAnother),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
