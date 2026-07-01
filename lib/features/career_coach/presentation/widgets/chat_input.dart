import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

/// Bottom composer: a multiline text field + a send button. Disabled while a
/// reply is streaming.
class ChatInput extends StatefulWidget {
  const ChatInput({
    required this.enabled,
    required this.onSend,
    super.key,
  });

  final bool enabled;
  final ValueChanged<String> onSend;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canSend = widget.enabled && _hasText;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                enabled: widget.enabled,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: l10n.coachInputHint,
                  filled: true,
                  fillColor:
                      theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _SendButton(enabled: canSend, onTap: _send, tooltip: l10n.coachSend),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.onTap,
    required this.tooltip,
  });

  final bool enabled;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: enabled ? AppColors.ctaGradient : null,
              color: enabled
                  ? null
                  : Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_upward_rounded,
              color: enabled
                  ? AppColors.white
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
