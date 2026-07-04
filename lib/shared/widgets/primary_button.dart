import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

/// Premium primary call-to-action: emerald gradient fill, soft brand glow,
/// tactile press-scale, and a built-in loading state.
///
/// Used for the main action on every screen so the CTA language stays
/// perfectly consistent.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final bool loading;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
      onTap: _enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _enabled ? 1 : 0.55,
          duration: AppDurations.fast,
          child: Container(
            height: 58,
            width: widget.expanded ? double.infinity : null,
            padding: widget.expanded
                ? null
                : const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: AppColors.ctaGradient,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: _enabled
                  ? [
                      BoxShadow(
                        color: AppColors.emerald
                            .withValues(alpha: dark ? 0.45 : 0.35),
                        blurRadius: _pressed ? 12 : 22,
                        offset: Offset(0, _pressed ? 4 : 10),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: widget.loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: widget.expanded
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        if (widget.icon != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Icon(widget.icon,
                              size: 20, color: AppColors.white),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
