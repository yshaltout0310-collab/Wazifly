import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/aurora_background.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../core/services/company/company_repository.dart';
import '../../../core/services/user_profile/user_profile_repository.dart';
import '../../auth/application/auth_providers.dart';
import '../application/user_type_controller.dart';
import '../domain/user_type.dart';

/// Lets the user pick their role: Job Seeker or Employer.
class UserTypeSelectionScreen extends ConsumerStatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  ConsumerState<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState
    extends ConsumerState<UserTypeSelectionScreen> {
  UserType? _selected;

  Future<void> _confirm() async {
    final selected = _selected;
    if (selected == null) return;
    await ref.read(userTypeControllerProvider.notifier).select(selected);

    // Persist the role to the user's Firestore profile (no-op until
    // Firebase is configured).
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      await ref
          .read(userProfileRepositoryProvider)
          .setUserType(user.uid, selected);
      // Employers get a company document seeded from their identity.
      if (selected == UserType.employer) {
        await ref.read(companyRepositoryProvider).ensureCompany(
              user.uid,
              email: user.email,
              name: user.displayName,
            );
      }
    }

    if (!mounted) return;
    context.goNamed(selected == UserType.employer
        ? RouteNames.employerHome
        : RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: AuroraBackground(
        intensity: 0.6,
        child: SafeArea(
          child: ResponsiveCenter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.horizontalGutter,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.userTypeTitle,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
                  ).animate().fadeIn().moveY(begin: 10, end: 0),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.userTypeSubtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ).animate(delay: 80.ms).fadeIn(),
                  const SizedBox(height: AppSpacing.xl),
                  _RoleCard(
                    icon: Icons.person_search_rounded,
                    title: l10n.jobSeeker,
                    description: l10n.jobSeekerDesc,
                    selected: _selected == UserType.jobSeeker,
                    onTap: () =>
                        setState(() => _selected = UserType.jobSeeker),
                  ).animate().fadeIn(delay: 140.ms).moveY(begin: 14, end: 0),
                  const SizedBox(height: AppSpacing.md),
                  _RoleCard(
                    icon: Icons.business_center_rounded,
                    title: l10n.employer,
                    description: l10n.employerDesc,
                    selected: _selected == UserType.employer,
                    onTap: () =>
                        setState(() => _selected = UserType.employer),
                  ).animate().fadeIn(delay: 240.ms).moveY(begin: 14, end: 0),
                  const Spacer(),
                  PrimaryButton(
                    label: l10n.confirm,
                    icon: Icons.check_rounded,
                    onPressed: _selected == null ? null : _confirm,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.10)
          : scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outline.withValues(alpha: 0.6),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: AppColors.white, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? scheme.primary
                    : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
