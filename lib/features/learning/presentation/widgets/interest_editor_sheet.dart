import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/models/learning_profile.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../application/learning_controller.dart';
import '../learning_l10n.dart';

/// Add/Edit bottom sheet for one learning interest (label + optional note).
///
/// When [existing] is null it adds to [category]; otherwise it edits [existing].
/// Persists through the [learningControllerProvider]; the reactive profile stream
/// re-renders the screen.
class InterestEditorSheet extends ConsumerStatefulWidget {
  const InterestEditorSheet({
    required this.category,
    this.existing,
    super.key,
  });

  final LearningCategory category;
  final LearningInterest? existing;

  static Future<void> show(
    BuildContext context, {
    required LearningCategory category,
    LearningInterest? existing,
  }) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) =>
            InterestEditorSheet(category: category, existing: existing),
      );

  @override
  ConsumerState<InterestEditorSheet> createState() =>
      _InterestEditorSheetState();
}

class _InterestEditorSheetState extends ConsumerState<InterestEditorSheet> {
  late final TextEditingController _label =
      TextEditingController(text: widget.existing?.label ?? '');
  late final TextEditingController _note =
      TextEditingController(text: widget.existing?.note ?? '');
  bool _busy = false;

  @override
  void dispose() {
    _label.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _label.text.trim();
    if (label.isEmpty || _busy) return;
    setState(() => _busy = true);
    final c = ref.read(learningControllerProvider.notifier);
    final ok = widget.existing == null
        ? await c.addInterest(
            category: widget.category, label: label, note: _note.text)
        : await c.editInterest(widget.existing!, label: label, note: _note.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg + viewInsets),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? l10n.learningEditTitle : l10n.learningAddTitle,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(widget.category.label(l10n),
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _label,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.learningAdd,
                hintText: l10n.learningLabelHint,
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _note,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(hintText: l10n.learningNoteHint),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: l10n.learningSave,
              onPressed: _busy ? null : _save,
              loading: _busy,
            ),
          ],
        ),
      ),
    );
  }
}
