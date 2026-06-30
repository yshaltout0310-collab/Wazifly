import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../country_selection/application/country_controller.dart';
import '../application/auth_providers.dart';
import 'auth_navigation.dart';
import 'otp_verification_screen.dart';
import 'widgets/auth_error.dart';
import 'widgets/auth_text_field.dart';

/// Collects a phone number and starts OTP verification.
class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendCode(String dialCode) async {
    final l10n = AppLocalizations.of(context);
    final digits = _controller.text.trim();
    if (digits.isEmpty) {
      showAuthSnack(context, l10n.fieldRequired, isError: true);
      return;
    }
    final fullNumber = '$dialCode$digits';
    FocusScope.of(context).unfocus();

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).verifyPhoneNumber(
        phoneNumber: fullNumber,
        onCodeSent: (verificationId) {
          if (!mounted) return;
          setState(() => _loading = false);
          context.pushNamed(
            RouteNames.otp,
            extra: OtpArgs(
              verificationId: verificationId,
              phoneNumber: fullNumber,
            ),
          );
        },
        onFailed: (error) {
          if (!mounted) return;
          setState(() => _loading = false);
          showAuthError(context, error);
        },
        onAutoVerified: (_) {
          if (!mounted) return;
          goAfterAuth(context, ref);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAuthError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final country = ref.watch(countryControllerProvider);
    final dialCode = country?.dialCode ?? '+';

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
                  l10n.phoneAuthTitle,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ).animate().fadeIn().moveY(begin: 10, end: 0),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.phoneAuthSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ).animate(delay: 80.ms).fadeIn(),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _DialCodeBox(
                      flag: country?.flag ?? '🌐',
                      dialCode: dialCode,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AuthTextField(
                        label: l10n.phoneLabel,
                        controller: _controller,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9 ]'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: l10n.sendCode,
                  icon: Icons.sms_outlined,
                  loading: _loading,
                  onPressed: () => _sendCode(dialCode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Displays the selected country's flag + dial code beside the number field.
class _DialCodeBox extends StatelessWidget {
  const _DialCodeBox({required this.flag, required this.dialCode});

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
