import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/password_policy.dart';

/// Live checklist of the password requirements, ticking off as the user types.
///
/// Rendered from [PasswordPolicy] itself, so the rules shown are by
/// construction the rules enforced. It exists because neither
/// password-creation path displayed anything at all: the requirement was
/// discoverable only by breaking it and reading the error.
///
/// Shown on password *creation* (sign-up, Change password) and never on
/// sign-in, where a creation-time rule has no business running.
class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({required this.password, super.key});

  /// The password as currently typed. An empty value shows every rule unmet
  /// rather than hiding the list — the point is to state the rules up front.
  final String password;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.passwordRequirementsTitle,
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final rule in PasswordRule.values)
          _RuleRow(
            label: _label(l10n, rule),
            met: PasswordPolicy.satisfies(rule, password),
          ),
      ],
    );
  }

  String _label(AppLocalizations l10n, PasswordRule rule) => switch (rule) {
        PasswordRule.minLength =>
          l10n.passwordRuleMinLength(PasswordPolicy.minLength),
        PasswordRule.letter => l10n.passwordRuleLetter,
        PasswordRule.digit => l10n.passwordRuleNumber,
      };
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = met
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      // One Semantics node per rule, so a screen reader announces the rule and
      // whether it is satisfied instead of reading a bare icon.
      child: Semantics(
        label: label,
        checked: met,
        inMutuallyExclusiveGroup: false,
        child: ExcludeSemantics(
          child: Row(
            children: [
              Icon(
                met
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: color,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
