import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/models/application_note.dart';

/// A single private note with edit / delete actions.
class ApplicationNoteTile extends StatelessWidget {
  const ApplicationNoteTile({
    required this.note,
    required this.onEdit,
    required this.onDelete,
    this.pending = false,
    super.key,
  });

  final ApplicationNote note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final fmt = DateFormat.yMMMd(locale).add_jm();
    final edited = note.updatedAt.difference(note.createdAt).inSeconds > 1;

    return Opacity(
      opacity: pending ? 0.6 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note.text,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.35)),
                  const SizedBox(height: 4),
                  Text(
                    edited
                        ? '${fmt.format(note.updatedAt)} · ${l10n.noteEditedTag}'
                        : fmt.format(note.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            PopupMenuButton<int>(
              icon: const Icon(Icons.more_horiz_rounded, size: 20),
              onSelected: (v) => v == 0 ? onEdit() : onDelete(),
              itemBuilder: (context) => [
                PopupMenuItem(
                    value: 0,
                    child: Row(children: [
                      const Icon(Icons.edit_outlined, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.noteEdit),
                    ])),
                PopupMenuItem(
                    value: 1,
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18, color: theme.colorScheme.error),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.noteDelete,
                          style: TextStyle(color: theme.colorScheme.error)),
                    ])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
