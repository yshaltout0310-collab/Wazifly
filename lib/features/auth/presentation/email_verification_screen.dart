import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../security/presentation/biometric_enrollment_sheet.dart';
import '../application/auth_providers.dart';
import 'auth_navigation.dart';
import 'widgets/auth_error.dart';

/// Email-verification gate. Shown after sign-up and whenever an unverified user
/// signs in. The account exists (and is signed in) but access is blocked until
/// the email address is verified. Offers "I've verified — Continue" (reloads and
/// re-checks), "Resend verification email" (with a short cooldown), and "Use a
/// different account" (signs out).
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  static const _resendCooldown = 30;

  bool _checking = false;
  bool _resending = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _checkVerified() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _checking = true);
    try {
      final verified =
          await ref.read(authRepositoryProvider).reloadEmailVerified();
      if (!mounted) return;
      if (!verified) {
        setState(() => _checking = false);
        showAuthSnack(context, l10n.verifyEmailNotYet, isError: true);
        return;
      }
      // Verified → continue into the app (offer biometric once, then route home).
      await maybeOfferBiometricEnrollment(context, ref);
      if (!mounted) return;
      goAfterAuth(context, ref);
    } catch (e) {
      if (!mounted) return;
      setState(() => _checking = false);
      showAuthError(context, e);
    }
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _resending = true);
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (!mounted) return;
      showAuthSnack(context, l10n.verifyEmailResent);
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      showAuthError(context, e);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _useAnother() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    context.goNamed(RouteNames.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final email = ref.watch(authRepositoryProvider).currentUser?.email ?? '';

    final canResend = !_resending && !_checking && _cooldown == 0;
    final resendLabel = _cooldown > 0
        ? l10n.verifyEmailResendIn(_cooldown)
        : l10n.verifyEmailResend;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ResponsiveCenter(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              context.horizontalGutter,
              AppSpacing.lg,
              context.horizontalGutter,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.mark_email_unread_outlined,
                        size: 42, color: theme.colorScheme.primary),
                  ),
                ).animate().scale(duration: 400.ms, curve: AppCurves.spring),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.verifyEmailTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ).animate().fadeIn().moveY(begin: 10, end: 0),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.verifyEmailBody(email),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ).animate(delay: 100.ms).fadeIn(),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: l10n.verifyEmailContinue,
                  loading: _checking,
                  onPressed: _checkVerified,
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: canResend ? _resend : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: _resending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Text(resendLabel),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: _checking ? null : _useAnother,
                  child: Text(l10n.verifyEmailUseAnother),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
