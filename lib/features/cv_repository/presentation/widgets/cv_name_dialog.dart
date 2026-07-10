import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/widgets/chip_input.dart';

/// The result of the CV name/tags dialog.
typedef CvNameResult = ({String name, List<String> tags});

/// Prompts for a CV name (+ optional tags). Returns null if cancelled.
Future<CvNameResult?> showCvNameDialog(
  BuildContext context, {
  required String title,
  String initialName = '',
  List<String> initialTags = const [],
  bool withTags = true,
}) {
  return showDialog<CvNameResult>(
    context: context,
    builder: (_) => _CvNameDialog(
      title: title,
      initialName: initialName,
      initialTags: initialTags,
      withTags: withTags,
    ),
  );
}

class _CvNameDialog extends StatefulWidget {
  const _CvNameDialog({
    required this.title,
    required this.initialName,
    required this.initialTags,
    required this.withTags,
  });

  final String title;
  final String initialName;
  final List<String> initialTags;
  final bool withTags;

  @override
  State<_CvNameDialog> createState() => _CvNameDialogState();
}

class _CvNameDialogState extends State<_CvNameDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName);
  late List<String> _tags = [...widget.initialTags];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((name: name, tags: _tags));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(labelText: l10n.cvNameLabel),
              onSubmitted: (_) => _submit(),
            ),
            if (widget.withTags) ...[
              const SizedBox(height: AppSpacing.md),
              ChipInput(
                label: l10n.cvTagsLabel,
                hint: l10n.cvTagsHint,
                icon: Icons.sell_outlined,
                values: _tags,
                onChanged: (v) => setState(() => _tags = v),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.cvSave)),
      ],
    );
  }
}
