import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/primary_button.dart';
import '../application/auth_providers.dart';
import 'auth_navigation.dart';
import 'widgets/auth_error.dart';

/// Arguments passed from the phone screen to the OTP screen.
class OtpArgs {
  const OtpArgs({required this.verificationId, required this.phoneNumber});
  final String verificationId;
  final String phoneNumber;
}

/// 6-digit OTP entry + verification.
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({required this.args, super.key});

  final OtpArgs args;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  final _controller = TextEditingController();
  late String _verificationId = widget.args.verificationId;
  bool _loading = false;

  static const int _otpLength = 6;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context);
    final code = _controller.text.trim();
    if (code.length != _otpLength) {
      showAuthSnack(context, l10n.invalidOtp, isError: true);
      return;
    }
    FocusScope.of(context).unfocus();

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).confirmSmsCode(
            verificationId: _verificationId,
            smsCode: code,
          );
      if (!mounted) return;
      goAfterAuth(context, ref);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAuthError(context, e);
    }
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context);
    await ref.read(authRepositoryProvider).verifyPhoneNumber(
          phoneNumber: widget.args.phoneNumber,
          onCodeSent: (id) {
            if (!mounted) return;
            setState(() => _verificationId = id);
            showAuthSnack(context, l10n.resendCode);
          },
          onFailed: (error) {
            if (mounted) showAuthError(context, error);
          },
        );
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppLogo(size: 60),
                ).animate().scale(duration: 400.ms, curve: AppCurves.spring),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.otpTitle,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ).animate().fadeIn().moveY(begin: 10, end: 0),
                const SizedBox(height: AppSpacing.sm),
                Text.rich(
                  TextSpan(
                    text: '${l10n.otpSubtitle} ',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                    children: [
                      TextSpan(
                        // LTR embedding (U+202A start, U+202C pop) keeps the
                        // "+countrycode" number left-to-right inside RTL text.
                        text: '${String.fromCharCode(0x202A)}'
                            '${widget.args.phoneNumber}'
                            '${String.fromCharCode(0x202C)}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 80.ms).fadeIn(),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: _otpLength,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 18,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    hintStyle: TextStyle(
                      letterSpacing: 18,
                      color: AppColors.emerald.withValues(alpha: 0.25),
                    ),
                  ),
                  onChanged: (v) {
                    if (v.length == _otpLength) _verify();
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: l10n.verify,
                  loading: _loading,
                  onPressed: _verify,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: _loading ? null : _resend,
                  child: Text(l10n.resendCode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
