import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/presentation/widgets/auth_error.dart';
import '../application/change_password_controller.dart';

/// Lets an email/password user set a new password (re-authentication is handled
/// in the auth repository).
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String _failureMessage(AppLocalizations l10n, ChangePasswordState state) {
    if (state.failure != null) {
      return switch (state.failure!) {
        ChangePasswordFailure.emptyFields => l10n.changePasswordEmptyFields,
        ChangePasswordFailure.tooShort => l10n.changePasswordTooShort,
        ChangePasswordFailure.mismatch => l10n.changePasswordMismatch,
      };
    }
    if (state.authError != null) {
      return localizedAuthMessage(l10n, state.authError!);
    }
    return l10n.authFailed;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final ok =
        await ref.read(changePasswordControllerProvider.notifier).submit(
              currentPassword: _current.text,
              newPassword: _next.text,
              confirmPassword: _confirm.text,
            );
    if (!mounted) return;
    if (ok) {
      showAuthSnack(context, l10n.changePasswordSuccess);
      if (context.canPop()) context.pop();
    } else {
      final state = ref.read(changePasswordControllerProvider);
      showAuthSnack(context, _failureMessage(l10n, state), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final submitting =
        ref.watch(changePasswordControllerProvider).isSubmitting;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.changePasswordTitle)),
      body: SafeArea(
        child: ResponsiveCenter(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.horizontalGutter,
              AppSpacing.lg,
              context.horizontalGutter,
              AppSpacing.xl,
            ),
            children: [
              Text(
                l10n.changePasswordSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _current,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: l10n.changePasswordCurrent,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscureCurrent
                        ? l10n.commonShowPassword
                        : l10n.commonHidePassword,
                    icon: Icon(_obscureCurrent
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _next,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: l10n.changePasswordNew,
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscureNew
                        ? l10n.commonShowPassword
                        : l10n.commonHidePassword,
                    icon: Icon(_obscureNew
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _confirm,
                obscureText: _obscureNew,
                onSubmitted: (_) => submitting ? null : _submit(),
                decoration: InputDecoration(
                  labelText: l10n.changePasswordConfirm,
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: l10n.changePasswordSubmit,
                icon: Icons.check_rounded,
                loading: submitting,
                onPressed: submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
