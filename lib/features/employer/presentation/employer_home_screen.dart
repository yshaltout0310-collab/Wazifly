import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/completion_indicator.dart';
import '../application/company_providers.dart';
import '../domain/company_stats.dart';

/// The employer's landing dashboard: company header, completion, quick recruiting
/// stats (zero until later milestones), a Company Profile entry, and placeholder
/// tools for upcoming milestones. Role-routed here when `userType == employer`.
class EmployerHomeScreen extends ConsumerWidget {
  const EmployerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final company = ref.watch(currentCompanyProvider);
    final completion = ref.watch(companyCompletionProvider);
    final stats = ref.watch(companyStatsProvider);

    final companyName = (company?.name?.trim().isNotEmpty ?? false)
        ? company!.name!.trim()
        : l10n.employerCompanyFallback;

    // Placeholder recruiting tools — go live in later milestones.
    final tools = <({IconData icon, String label})>[
      (icon: Icons.post_add_rounded, label: l10n.employerPostJob),
      (icon: Icons.people_alt_outlined, label: l10n.employerApplicants),
      (icon: Icons.event_available_outlined, label: l10n.employerInterviews),
      (icon: Icons.groups_outlined, label: l10n.employerCandidates),
    ];

    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 720,
          child: ListView(
            padding: EdgeInsets.fromLTRB(context.horizontalGutter,
                AppSpacing.md, context.horizontalGutter, AppSpacing.xxl),
            children: [
              _Header(
                greeting: l10n.homeGreeting,
                companyName: companyName,
                logoUrl: company?.logoUrl,
                settingsTooltip: l10n.settings,
                onOpenSettings: () => context.pushNamed(RouteNames.settings),
              ).animate().fadeIn().moveY(begin: -8, end: 0),
              const SizedBox(height: AppSpacing.lg),
              _StatsGrid(stats: stats)
                  .animate(delay: 80.ms)
                  .fadeIn()
                  .moveY(begin: 10, end: 0),
              const SizedBox(height: AppSpacing.lg),
              CompletionIndicator(
                percent: completion,
                title: l10n.companyCompletionTitle,
                nudge: l10n.companyCompletionNudge,
                complete: l10n.companyCompletionComplete,
              ).animate(delay: 140.ms).fadeIn().moveY(begin: 10, end: 0),
              const SizedBox(height: AppSpacing.md),
              _CompanyCta(
                icon: Icons.apartment_rounded,
                title: l10n.employerCompanyProfile,
                subtitle: l10n.employerCompanyProfileSubtitle,
                onTap: () => context.pushNamed(RouteNames.companyProfile),
              ).animate(delay: 200.ms).fadeIn().moveY(begin: 10, end: 0),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.employerToolsTitle,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.employerToolsSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.3,
                children: [
                  for (var i = 0; i < tools.length; i++)
                    _ToolCard(
                      icon: tools[i].icon,
                      label: tools[i].label,
                      soonLabel: l10n.comingSoonBadge,
                      onTap: () => ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(l10n.homeComingSoon),
                          ),
                        ),
                    )
                        .animate(delay: (220 + i * 70).ms)
                        .fadeIn()
                        .moveY(begin: 14, end: 0),
                ],
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
    required this.companyName,
    required this.logoUrl,
    required this.settingsTooltip,
    required this.onOpenSettings,
  });

  final String greeting;
  final String companyName;
  final String? logoUrl;
  final String settingsTooltip;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: AppColors.ctaGradient,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.brandGlow,
            image: logoUrl != null
                ? DecorationImage(image: NetworkImage(logoUrl!), fit: BoxFit.cover)
                : null,
          ),
          alignment: Alignment.center,
          child: logoUrl == null
              ? const Icon(Icons.business_rounded, color: AppColors.white, size: 26)
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
                companyName,
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

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final CompanyStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tiles = <({IconData icon, String label, int value})>[
      (icon: Icons.work_outline_rounded, label: l10n.employerStatActiveJobs, value: stats.activeJobs),
      (icon: Icons.description_outlined, label: l10n.employerStatApplications, value: stats.applications),
      (icon: Icons.event_available_outlined, label: l10n.employerStatInterviews, value: stats.interviews),
      (icon: Icons.emoji_events_outlined, label: l10n.employerStatHires, value: stats.hires),
    ];
    return Column(
      children: [
        Row(children: [
          Expanded(child: _StatTile(tile: tiles[0])),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _StatTile(tile: tiles[1])),
        ]),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(child: _StatTile(tile: tiles[2])),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _StatTile(tile: tiles[3])),
        ]),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.tile});
  final ({IconData icon, String label, int value}) tile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        boxShadow: AppShadows.card(dark: dark),
      ),
      child: Row(
        children: [
          Icon(tile.icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tile.value}',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  tile.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyCta extends StatelessWidget {
  const _CompanyCta({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.5)),
            boxShadow: AppShadows.card(dark: dark),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6))),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded,
                  color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.label,
    required this.soonLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String soonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.5)),
            boxShadow: AppShadows.card(dark: dark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(icon,
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.8)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(soonLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6))),
                  ),
                ],
              ),
              const Spacer(),
              Text(label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
