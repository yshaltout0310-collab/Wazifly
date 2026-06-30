import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/aurora_background.dart';
import '../../../shared/widgets/primary_button.dart';
import '../application/auth_providers.dart';
import 'auth_navigation.dart';
import 'widgets/auth_error.dart';
import 'widgets/auth_method_button.dart';

/// Authentication landing screen: pick a sign-in method.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _googleLoading = false;

  Future<void> _google() async {
    setState(() => _googleLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      if (!mounted) return;
      goAfterAuth(context, ref);
    } catch (e) {
      if (!mounted) return;
      showAuthError(context, e);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final notConfigured = ref.watch(firebaseNotConfiguredProvider);

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: ResponsiveCenter(
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: context.horizontalGutter),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  const AppLogo(size: 104)
                      .animate()
                      .scale(duration: 500.ms, curve: AppCurves.spring)
                      .fadeIn(),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.welcomeTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
                  ).animate(delay: 120.ms).fadeIn().moveY(begin: 14, end: 0),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.welcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.65),
                    ),
                  ).animate(delay: 220.ms).fadeIn(),
                  const Spacer(flex: 4),
                  PrimaryButton(
                    label: l10n.continueWithEmail,
                    icon: Icons.mail_outline_rounded,
                    onPressed: () => context.pushNamed(RouteNames.emailAuth),
                  ).animate(delay: 320.ms).fadeIn().moveY(begin: 16, end: 0),
                  const SizedBox(height: AppSpacing.lg),
                  _OrDivider(label: l10n.authOr)
                      .animate(delay: 380.ms)
                      .fadeIn(),
                  const SizedBox(height: AppSpacing.lg),
                  AuthMethodButton(
                    label: l10n.continueWithGoogle,
                    iconWidget: const GoogleGlyph(),
                    loading: _googleLoading,
                    onPressed: _google,
                  ).animate(delay: 440.ms).fadeIn().moveY(begin: 16, end: 0),
                  const SizedBox(height: AppSpacing.md),
                  AuthMethodButton(
                    label: l10n.continueWithPhone,
                    icon: Icons.phone_outlined,
                    onPressed: () => context.pushNamed(RouteNames.phoneAuth),
                  ).animate(delay: 520.ms).fadeIn().moveY(begin: 16, end: 0),
                  const SizedBox(height: AppSpacing.lg),
                  if (notConfigured)
                    _SetupNotice(message: l10n.demoModeNotice)
                        .animate(delay: 600.ms)
                        .fadeIn(),
                  const Spacer(flex: 1),
                  Text(
                    l10n.termsNote,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.6);
    return Row(
      children: [
        Expanded(child: Divider(color: color, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
        ),
        Expanded(child: Divider(color: color, thickness: 1)),
      ],
    );
  }
}

/// Informational banner shown only until real Firebase credentials are added.
class _SetupNotice extends StatelessWidget {
  const _SetupNotice({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
