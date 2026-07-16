import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/aurora_background.dart';
import '../../../shared/widgets/primary_button.dart';

/// Authentication landing screen. The MVP uses **email & password only**, so
/// this offers a single "Continue with Email" action into the sign-in / sign-up
/// screen.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

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
