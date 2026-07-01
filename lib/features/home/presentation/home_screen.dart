import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../auth/application/auth_providers.dart';
import '../../user_type/application/user_type_controller.dart';
import '../../user_type/domain/user_type.dart';

/// Premium post-auth dashboard. Confirms the Phase 1 flow end-to-end and
/// previews the Phase 2 AI toolkit as "coming soon" tiles.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).valueOrNull;
    final type = ref.watch(userTypeControllerProvider);

    final roleLabel = switch (type) {
      UserType.jobSeeker => l10n.jobSeeker,
      UserType.employer => l10n.employer,
      null => '',
    };

    // `route` is non-null once a feature is live; null features still show the
    // "Soon" badge and a coming-soon toast.
    final features = <({IconData icon, String label, String? route})>[
      (
        icon: Icons.description_outlined,
        label: l10n.featResumeAnalyzer,
        route: RouteNames.resumeAnalyzer,
      ),
      (icon: Icons.bolt_outlined, label: l10n.featJobMatching, route: null),
      (icon: Icons.psychology_outlined, label: l10n.featCareerCoach, route: null),
      (icon: Icons.edit_document, label: l10n.featCvBuilder, route: null),
      (
        icon: Icons.record_voice_over_outlined,
        label: l10n.featInterviewPrep,
        route: null,
      ),
      (icon: Icons.recommend_outlined, label: l10n.featRecommendations, route: null),
    ];

    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 720,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  context.horizontalGutter,
                  AppSpacing.md,
                  context.horizontalGutter,
                  AppSpacing.md,
                ),
                sliver: SliverToBoxAdapter(
                  child: _Header(
                    greeting: l10n.homeGreeting,
                    name: user?.label ?? '',
                    photoUrl: user?.photoUrl,
                    settingsTooltip: l10n.settings,
                    onOpenSettings: () =>
                        context.pushNamed(RouteNames.settings),
                  ).animate().fadeIn().moveY(begin: -8, end: 0),
                ),
              ),
              SliverPadding(
                padding:
                    EdgeInsets.symmetric(horizontal: context.horizontalGutter),
                sliver: SliverToBoxAdapter(
                  child: _WelcomeBanner(
                    title: l10n.homeWelcome,
                    roleLabel: roleLabel,
                    roleIcon: type == UserType.employer
                        ? Icons.business_center_rounded
                        : Icons.person_search_rounded,
                  ).animate(delay: 100.ms).fadeIn().scaleXY(
                        begin: 0.97,
                        end: 1,
                        curve: AppCurves.spring,
                      ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  context.horizontalGutter,
                  AppSpacing.xl,
                  context.horizontalGutter,
                  AppSpacing.sm,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeToolkitTitle,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.homeToolkitSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  context.horizontalGutter,
                  AppSpacing.sm,
                  context.horizontalGutter,
                  AppSpacing.xl,
                ),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    // Slightly taller cards so longer labels (e.g. the Arabic
                    // "AI Job Matching") fit on two lines without overflowing.
                    childAspectRatio: 1.42,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final feature = features[i];
                      final route = feature.route;
                      return _FeatureCard(
                        icon: feature.icon,
                        label: feature.label,
                        soonLabel: l10n.comingSoonBadge,
                        available: route != null,
                        onTap: route != null
                            ? () => context.pushNamed(route)
                            : () => ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(l10n.homeComingSoon),
                                ),
                              ),
                      )
                          .animate(delay: (120 + i * 70).ms)
                          .fadeIn()
                          .moveY(begin: 14, end: 0);
                    },
                    childCount: features.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.name,
    required this.photoUrl,
    required this.settingsTooltip,
    required this.onOpenSettings,
  });

  final String greeting;
  final String name;
  final String? photoUrl;
  final String settingsTooltip;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: AppColors.ctaGradient,
            shape: BoxShape.circle,
            boxShadow: AppShadows.brandGlow,
            image: photoUrl != null
                ? DecorationImage(
                    image: NetworkImage(photoUrl!), fit: BoxFit.cover)
                : null,
          ),
          alignment: Alignment.center,
          child: photoUrl == null
              ? Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: settingsTooltip,
          onPressed: onOpenSettings,
          icon: const Icon(Icons.settings_rounded),
        ),
      ],
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({
    required this.title,
    required this.roleLabel,
    required this.roleIcon,
  });

  final String title;
  final String roleLabel;
  final IconData roleIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.ctaGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.brandGlow,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.white, size: 30),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (roleLabel.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(roleIcon, size: 15, color: AppColors.white),
                        const SizedBox(width: 6),
                        Text(
                          roleLabel,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.soonLabel,
    required this.available,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String soonLabel;

  /// Live feature → show an open affordance; otherwise show the "Soon" badge.
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
            boxShadow: AppShadows.card(dark: dark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                    ),
                    child: Icon(icon, color: scheme.primary, size: 22),
                  ),
                  const Spacer(),
                  if (available)
                    Icon(Icons.arrow_outward_rounded,
                        size: 20, color: scheme.primary)
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        soonLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                label,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
