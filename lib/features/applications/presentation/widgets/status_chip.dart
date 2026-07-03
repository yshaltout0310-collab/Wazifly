import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/models/application.dart';

/// Localized display name for an application status.
String applicationStatusLabel(AppLocalizations l10n, ApplicationStatus s) =>
    switch (s) {
      ApplicationStatus.pending => l10n.statusPending,
      ApplicationStatus.reviewed => l10n.statusReviewed,
      ApplicationStatus.interview => l10n.statusInterview,
      ApplicationStatus.accepted => l10n.statusAccepted,
      ApplicationStatus.rejected => l10n.statusRejected,
    };

/// Brand-aligned color per status.
Color applicationStatusColor(ApplicationStatus s) => switch (s) {
      ApplicationStatus.pending => const Color(0xFF6B7280), // slate
      ApplicationStatus.reviewed => AppColors.teal,
      ApplicationStatus.interview => AppColors.warning,
      ApplicationStatus.accepted => AppColors.emerald,
      ApplicationStatus.rejected => AppColors.error,
    };

IconData applicationStatusIcon(ApplicationStatus s) => switch (s) {
      ApplicationStatus.pending => Icons.hourglass_empty_rounded,
      ApplicationStatus.reviewed => Icons.visibility_outlined,
      ApplicationStatus.interview => Icons.event_available_outlined,
      ApplicationStatus.accepted => Icons.check_circle_rounded,
      ApplicationStatus.rejected => Icons.cancel_outlined,
    };

/// A pill showing an application's status with its color + icon.
class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, this.compact = false, super.key});

  final ApplicationStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = applicationStatusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(applicationStatusIcon(status), size: compact ? 12 : 14, color: color),
          const SizedBox(width: 5),
          Text(
            applicationStatusLabel(l10n, status),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
