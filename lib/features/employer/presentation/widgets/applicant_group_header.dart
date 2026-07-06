import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_dimensions.dart';

/// A section header in the grouped applicants list: the job title + applicant
/// count.
class ApplicantGroupHeader extends StatelessWidget {
  const ApplicantGroupHeader({
    required this.jobTitle,
    required this.count,
    super.key,
  });

  final String jobTitle;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
          top: AppSpacing.md, bottom: AppSpacing.sm, left: 2, right: 2),
      child: Row(
        children: [
          Icon(Icons.work_outline_rounded,
              size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              jobTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l10n.applicantsCount(count),
            style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
