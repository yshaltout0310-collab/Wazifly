import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimensions.dart';

/// The read-only country flag + dial code shown beside a national phone number
/// field.
///
/// Extracted from `phone_verification_screen` so sign-up and phone
/// verification render the same control rather than two copies that can drift —
/// in particular the RTL handling below, which is easy to lose in a duplicate.
class DialCodeBox extends StatelessWidget {
  const DialCodeBox({required this.flag, required this.dialCode, super.key});

  final String flag;
  final String dialCode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 6),
          Text(
            dialCode,
            // Keep "+974" LTR so the leading "+" isn't reordered in Arabic/RTL.
            textDirection: TextDirection.ltr,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
