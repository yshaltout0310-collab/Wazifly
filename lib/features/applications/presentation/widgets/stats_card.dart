import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../application/applications_controller.dart';

/// The Applications Center header: Applied / Saved / Interviews / Offers.
class StatsCard extends StatelessWidget {
  const StatsCard({required this.stats, super.key});

  final ApplicationStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.ctaGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.brandGlow,
      ),
      child: Row(
        children: [
          _Stat(
              value: stats.applied,
              label: l10n.statApplied,
              icon: Icons.send_rounded),
          _divider(),
          _Stat(
              value: stats.saved,
              label: l10n.statSaved,
              icon: Icons.bookmark_rounded),
          _divider(),
          _Stat(
              value: stats.interviews,
              label: l10n.statInterviews,
              icon: Icons.event_available_rounded),
          _divider(),
          _Stat(
              value: stats.offers,
              label: l10n.statOffers,
              icon: Icons.workspace_premium_rounded),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: AppColors.white.withValues(alpha: 0.22),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.icon});

  final int value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.white.withValues(alpha: 0.9), size: 20),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
