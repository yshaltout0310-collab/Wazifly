import 'package:flutter/material.dart';

import '../../core/localization/generated/app_localizations.dart';
import '../../core/theme/app_dimensions.dart';
import '../models/application.dart';
import 'application_status_style.dart';

/// A pill showing an application's status with its color + icon. Shared by the
/// seeker Applications Center and the employer Applicants Management.
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
