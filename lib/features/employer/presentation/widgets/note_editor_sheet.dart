import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/responsive.dart';

/// Shows a modal bottom sheet to add or edit a private note. Returns the trimmed
/// text on save, or null on cancel. The controller is owned by a
/// [StatefulWidget] (disposed after the route unmounts — the M2 dialog bug).
Future<String?> showNoteEditor(BuildContext context, {String? initialText}) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _NoteEditorSheet(initialText: initialText),
    );

class _NoteEditorSheet extends StatefulWidget {
  const _NoteEditorSheet({this.initialText});

  final String? initialText;

  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.initialText != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: ResponsiveCenter(
          maxWidth: 640,
          child: Padding(
            padding: EdgeInsets.fromLTRB(context.horizontalGutter, 0,
                context.horizontalGutter, AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? l10n.noteEditTitle : l10n.noteAdd,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.notesPrivateHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(hintText: l10n.noteHint),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_controller.text.trim()),
                    child: Text(l10n.noteSave),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
