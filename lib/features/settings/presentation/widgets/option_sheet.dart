import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimensions.dart';

/// One selectable option in [showOptionSheet].
class OptionItem<T> {
  const OptionItem({required this.value, required this.label, this.leading});
  final T value;
  final String label;
  final Widget? leading;
}

/// Shows a premium modal bottom sheet for picking a single value (used for the
/// language and theme pickers in Settings).
Future<void> showOptionSheet<T>({
  required BuildContext context,
  required String title,
  required List<OptionItem<T>> options,
  required T current,
  required ValueChanged<T> onSelected,
}) {
  final theme = Theme.of(context);

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  bottom: AppSpacing.md,
                  left: AppSpacing.xs,
                ),
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              for (final option in options)
                _OptionRow<T>(
                  option: option,
                  selected: option.value == current,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    if (option.value != current) onSelected(option.value);
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final OptionItem<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.10)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected
                    ? scheme.primary
                    : scheme.outline.withValues(alpha: 0.4),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                if (option.leading != null) ...[
                  option.leading!,
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Text(
                    option.label,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
