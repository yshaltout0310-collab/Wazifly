import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/models/internship_details_l10n.dart';
import '../../../../shared/models/job.dart';

/// A tappable internship row: title, company, key internship chips (funding /
/// work-mode / duration), and a "trains beginners" marker. Opens the shared job
/// detail (`/jobs/:id`) — internships reuse the jobs detail surface.
class InternshipTile extends StatelessWidget {
  const InternshipTile({required this.job, required this.onTap, super.key});

  final Job job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final d = job.internship;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        boxShadow: AppShadows.card(dark: dark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  job.company,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (job.location.isNotEmpty)
                      _Chip(
                          icon: (d?.workMode?.isRemoteish ?? job.remote)
                              ? Icons.public_rounded
                              : Icons.place_outlined,
                          label: job.location),
                    if (d?.funding != null)
                      _Chip(
                          icon: Icons.payments_outlined,
                          label: d!.funding!.label(l10n)),
                    if (d?.workMode != null)
                      _Chip(
                          icon: Icons.laptop_mac_outlined,
                          label: d!.workMode!.label(l10n)),
                    if (d?.duration != null)
                      _Chip(
                          icon: Icons.schedule_outlined,
                          label: d!.duration!.label(l10n)),
                    if (job.trainsBeginners)
                      _Chip(
                        icon: Icons.emoji_objects_outlined,
                        label: l10n.trainsBeginnersBadge,
                        color: AppColors.teal,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final bg = color?.withValues(alpha: 0.12) ??
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 5),
          Text(label,
              style: theme.textTheme.labelMedium?.copyWith(
                  color: color ??
                      theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  fontWeight: color != null ? FontWeight.w700 : null)),
        ],
      ),
    );
  }
}
