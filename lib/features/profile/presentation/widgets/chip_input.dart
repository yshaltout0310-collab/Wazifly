import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_dimensions.dart';

/// A labeled tag editor: shows the current [values] as removable chips and a
/// text field to add more. Used for Skills and Preferred Job Titles.
///
/// De-duplication (case-insensitive) and trimming are handled here so callers
/// just persist [onChanged]'s list.
class ChipInput extends StatefulWidget {
  const ChipInput({
    required this.label,
    required this.hint,
    required this.icon,
    required this.values,
    required this.onChanged,
    super.key,
  });

  final String label;
  final String hint;
  final IconData icon;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  @override
  State<ChipInput> createState() => _ChipInputState();
}

class _ChipInputState extends State<ChipInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final exists =
        widget.values.any((v) => v.toLowerCase() == text.toLowerCase());
    if (!exists) {
      widget.onChanged([...widget.values, text]);
    }
    _controller.clear();
  }

  void _remove(String value) {
    widget.onChanged(widget.values.where((v) => v != value).toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (widget.values.isNotEmpty) ...[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final value in widget.values)
                Chip(
                  label: Text(value),
                  onDeleted: () => _remove(value),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _add(),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: Icon(widget.icon),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filledTonal(
              onPressed: _add,
              icon: const Icon(Icons.add_rounded),
              tooltip: l10n.profileChipAdd,
            ),
          ],
        ),
      ],
    );
  }
}
