import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../domain/chat_message.dart';

/// A single chat bubble. User messages are emerald and end-aligned; assistant
/// messages are surface-colored and start-aligned. Handles the streaming
/// (typing) and failed states.
class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.message, required this.onRetry, super.key});

  final ChatMessage message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment:
          isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          gradient: isUser ? AppColors.ctaGradient : null,
          color: isUser ? null : theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(isUser ? AppRadius.lg : AppRadius.sm),
            bottomRight: Radius.circular(isUser ? AppRadius.sm : AppRadius.lg),
          ),
          border: isUser
              ? null
              : Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
          boxShadow: isUser ? AppShadows.brandGlow : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.42,
                  color: isUser ? AppColors.white : theme.colorScheme.onSurface,
                ),
              ),
            if (message.isStreaming && message.text.isEmpty)
              _TypingIndicator(color: theme.colorScheme.primary),
            if (message.isFailed) ...[
              if (message.text.isNotEmpty) const SizedBox(height: 6),
              InkWell(
                onTap: onRetry,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh_rounded,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text(
                      l10n.coachRetry,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small animated "typing" indicator shown before the first token arrives.
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.color});
  final Color color;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = ((_c.value + i * 0.2) % 1.0);
              final opacity = 0.3 + 0.7 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
