import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../security/presentation/biometric_enrollment_sheet.dart';
import '../application/auth_providers.dart';
import 'auth_navigation.dart';
import 'widgets/auth_error.dart';
import 'widgets/auth_text_field.dart';

/// Email + password sign-in / sign-up screen with a mode toggle.
class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value, AppLocalizations l10n) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l10n.fieldRequired;
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!emailRegex.hasMatch(v)) return l10n.invalidEmail;
    return null;
  }

  String? _validatePassword(String? value, AppLocalizations l10n) {
    final v = value ?? '';
    if (v.isEmpty) return l10n.fieldRequired;
    if (v.length < 6) return l10n.passwordTooShort;
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _loading = true);
    final repo = ref.read(authRepositoryProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isSignUp) {
        await repo.registerWithEmail(email: email, password: password);
      } else {
        await repo.signInWithEmail(email: email, password: password);
      }
      if (!mounted) return;
      // Offer biometric login once (respects a prior "Not Now"); never blocks.
      await maybeOfferBiometricEnrollment(context, ref);
      if (!mounted) return;
      goAfterAuth(context, ref);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAuthError(context, e);
    }
  }

  Future<void> _forgotPassword() async {
    final l10n = AppLocalizations.of(context);
    if (_validateEmail(_emailController.text, l10n) != null) {
      showAuthSnack(context, l10n.invalidEmail, isError: true);
      return;
    }
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordReset(_emailController.text.trim());
      if (!mounted) return;
      showAuthSnack(context, l10n.passwordResetSent);
    } catch (e) {
      if (!mounted) return;
      showAuthError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ResponsiveCenter(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              context.horizontalGutter,
              AppSpacing.sm,
              context.horizontalGutter,
              AppSpacing.xl,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppLogo(size: 60),
                  ).animate().scale(
                        duration: 400.ms,
                        curve: AppCurves.spring,
                      ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    _isSignUp
                        ? l10n.emailAuthTitleSignUp
                        : l10n.emailAuthTitleSignIn,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ).animate().fadeIn().moveY(begin: 10, end: 0),
                  const SizedBox(height: AppSpacing.xl),
                  AuthTextField(
                    label: l10n.emailLabel,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline_rounded,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) => _validateEmail(v, l10n),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AuthTextField(
                    label: l10n.passwordLabel,
                    controller: _passwordController,
                    obscureText: _obscure,
                    prefixIcon: Icons.lock_outline_rounded,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    validator: (v) => _validatePassword(v, l10n),
                    suffix: IconButton(
                      tooltip: _obscure
                          ? l10n.commonShowPassword
                          : l10n.commonHidePassword,
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  if (!_isSignUp)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: _loading ? null : _forgotPassword,
                        child: Text(l10n.forgotPassword),
                      ),
                    )
                  else
                    const SizedBox(height: AppSpacing.md),
                  const SizedBox(height: AppSpacing.sm),
                  PrimaryButton(
                    label: _isSignUp ? l10n.signUp : l10n.signIn,
                    loading: _loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Wrap (not Row) so the prompt + action flow to a second line
                  // instead of overflowing on narrow screens or with longer
                  // translations (e.g. Arabic).
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _isSignUp
                            ? l10n.haveAccountPrompt
                            : l10n.noAccountPrompt,
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(_isSignUp ? l10n.signIn : l10n.signUp),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
