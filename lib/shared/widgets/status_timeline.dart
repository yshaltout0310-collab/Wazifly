import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/localization/generated/app_localizations.dart';
import '../../core/theme/app_dimensions.dart';
import '../models/application.dart';
import 'application_status_style.dart';

/// Vertical timeline of an application's status history (oldest → newest). Shared
/// by the seeker Applications Center and the employer Applicants Management.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({required this.history, super.key});

  final List<ApplicationEvent> history;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final fmt = DateFormat.yMMMd(locale).add_jm();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < history.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 3),
                      decoration: BoxDecoration(
                        color: applicationStatusColor(history[i].status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i != history.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: theme.colorScheme.outline.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: i == history.length - 1 ? 0 : AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          applicationStatusLabel(l10n, history[i].status),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fmt.format(history[i].at),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        if ((history[i].note ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            history[i].note!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
