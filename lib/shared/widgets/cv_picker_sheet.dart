import 'package:flutter/material.dart';

import '../../core/localization/generated/app_localizations.dart';
import '../../core/services/cv_repository/cv_document.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

/// Lets the user choose which CV to submit for a job application. Returns the
/// chosen [CvDocument], or null if dismissed. [preselectedId] (last-used/default)
/// is highlighted first.
Future<CvDocument?> showCvPickerSheet(
  BuildContext context, {
  required List<CvDocument> cvs,
  String? preselectedId,
}) {
  return showModalBottomSheet<CvDocument>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _CvPickerSheet(cvs: cvs, preselectedId: preselectedId),
  );
}

class _CvPickerSheet extends StatefulWidget {
  const _CvPickerSheet({required this.cvs, this.preselectedId});

  final List<CvDocument> cvs;
  final String? preselectedId;

  @override
  State<_CvPickerSheet> createState() => _CvPickerSheetState();
}

class _CvPickerSheetState extends State<_CvPickerSheet> {
  late String _selectedId = _initialSelection();

  String _initialSelection() {
    if (widget.preselectedId != null &&
        widget.cvs.any((c) => c.id == widget.preselectedId)) {
      return widget.preselectedId!;
    }
    final def = widget.cvs.where((c) => c.isDefault);
    if (def.isNotEmpty) return def.first.id;
    return widget.cvs.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.cvPickerTitle,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(l10n.cvPickerSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.65))),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final cv in widget.cvs)
                    ListTile(
                      onTap: () => setState(() => _selectedId = cv.id),
                      leading: Icon(
                        _selectedId == cv.id
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: _selectedId == cv.id ? AppColors.emerald : null,
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(cv.name,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          if (cv.isDefault) ...[
                            const SizedBox(width: AppSpacing.xs),
                            _defaultTag(theme, l10n.cvDefaultBadge),
                          ],
                        ],
                      ),
                      subtitle: cv.atsScore != null
                          ? Text(l10n.cvAtsScore(cv.atsScore!))
                          : null,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: () {
                final chosen =
                    widget.cvs.firstWhere((c) => c.id == _selectedId);
                Navigator.of(context).pop(chosen);
              },
              icon: const Icon(Icons.send_rounded),
              label: Text(l10n.cvPickerApply),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultTag(ThemeData theme, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.emerald.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.emerald, fontWeight: FontWeight.w700)),
      );
}
