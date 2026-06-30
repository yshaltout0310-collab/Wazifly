import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimensions.dart';

/// Premium full-width button for a secondary authentication method
/// (Google, Phone…). Surface fill, hairline border, soft shadow, press-scale,
/// and an inline loading spinner.
class AuthMethodButton extends StatefulWidget {
  const AuthMethodButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconWidget,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? iconWidget;
  final bool loading;

  @override
  State<AuthMethodButton> createState() => _AuthMethodButtonState();
}

class _AuthMethodButtonState extends State<AuthMethodButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
      onTap: _enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: scheme.outline.withValues(alpha: dark ? 0.5 : 0.7),
            ),
            boxShadow: AppShadows.card(dark: dark),
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.iconWidget != null)
                        widget.iconWidget!
                      else if (widget.icon != null)
                        Icon(widget.icon, size: 22, color: scheme.onSurface),
                      const SizedBox(width: AppSpacing.sm + 2),
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
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

/// Multi-color "G" mark for the Google button (asset-free).
class GoogleGlyph extends StatelessWidget {
  const GoogleGlyph({this.size = 20, super.key});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Text(
        'G',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF4285F4),
          height: 1.0,
        ),
      ),
    );
  }
}
