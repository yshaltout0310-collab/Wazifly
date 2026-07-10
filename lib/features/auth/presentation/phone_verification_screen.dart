import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../country_selection/application/country_controller.dart';
import '../application/phone_link_controller.dart';
import 'widgets/auth_error.dart';
import 'widgets/auth_text_field.dart';

/// Phone verification that **links** a number to the signed-in account
/// (strengthening it — never a phone-only sign-in). Reached from Security
/// Settings. Single screen: number entry → OTP entry via an AnimatedSwitcher.
class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final _numberController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _handleLocalFailure(PhoneLinkFailure? failure) {
    if (failure == null) return;
    final l10n = AppLocalizations.of(context);
    final message = switch (failure) {
      PhoneLinkFailure.emptyNumber => l10n.fieldRequired,
      PhoneLinkFailure.invalidCode => l10n.invalidOtp,
    };
    showAuthSnack(context, message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(phoneLinkControllerProvider);

    // React to terminal outcomes and errors without rebuilding for them.
    ref.listen<PhoneLinkState>(phoneLinkControllerProvider, (prev, next) {
      if (next.stage == PhoneLinkStage.linked &&
          prev?.stage != PhoneLinkStage.linked) {
        showAuthSnack(context, l10n.phoneLinkedSuccess);
        if (context.mounted) context.pop();
        return;
      }
      if (next.error != null && next.error != prev?.error) {
        showAuthError(context, next.error!);
      }
      if (next.localFailure != null && next.localFailure != prev?.localFailure) {
        _handleLocalFailure(next.localFailure);
      }
    });

    final onNumberStage = state.stage == PhoneLinkStage.enterNumber ||
        state.stage == PhoneLinkStage.sendingCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.securityVerifyPhoneTitle)),
      body: SafeArea(
        child: ResponsiveCenter(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              context.horizontalGutter,
              AppSpacing.sm,
              context.horizontalGutter,
              AppSpacing.xl,
            ),
            child: AnimatedSwitcher(
              duration: AppDurations.medium,
              child: onNumberStage
                  ? _NumberEntry(
                      key: const ValueKey('number'),
                      controller: _numberController,
                      busy: state.stage == PhoneLinkStage.sendingCode,
                      onSend: (dialCode) => ref
                          .read(phoneLinkControllerProvider.notifier)
                          .sendCode('$dialCode${_numberController.text.trim()}'),
                    )
                  : _CodeEntry(
                      key: const ValueKey('code'),
                      controller: _codeController,
                      state: state,
                      onVerify: () => ref
                          .read(phoneLinkControllerProvider.notifier)
                          .submitCode(_codeController.text),
                      onResend: () => ref
                          .read(phoneLinkControllerProvider.notifier)
                          .resend(),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberEntry extends ConsumerWidget {
  const _NumberEntry({
    required this.controller,
    required this.busy,
    required this.onSend,
    super.key,
  });

  final TextEditingController controller;
  final bool busy;
  final void Function(String dialCode) onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final country = ref.watch(countryControllerProvider);
    final dialCode = country?.dialCode ?? '+';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppLogo(size: 60),
        ).animate().scale(duration: 400.ms, curve: AppCurves.spring),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.securityVerifyPhoneTitle,
          style: theme.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.securityVerifyPhoneSubtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _DialCodeBox(flag: country?.flag ?? '🌐', dialCode: dialCode),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AuthTextField(
                label: l10n.phoneLabel,
                controller: controller,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                autofillHints: const [AutofillHints.telephoneNumber],
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: l10n.sendCode,
          icon: Icons.sms_outlined,
          loading: busy,
          onPressed: () => onSend(dialCode),
        ),
      ],
    );
  }
}

class _CodeEntry extends StatelessWidget {
  const _CodeEntry({
    required this.controller,
    required this.state,
    required this.onVerify,
    required this.onResend,
    super.key,
  });

  final TextEditingController controller;
  final PhoneLinkState state;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  String _countdown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
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
        ),
        const SizedBox(height: AppSpacing.sm),
        Text.rich(
          TextSpan(
            text: '${l10n.otpSubtitle} ',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
            children: [
              TextSpan(
                // LTR embedding keeps "+countrycode" left-to-right within RTL.
                text: '${String.fromCharCode(0x202A)}'
                    '${state.phoneNumber ?? ''}'
                    '${String.fromCharCode(0x202C)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: PhoneLinkController.otpLength,
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
            if (v.length == PhoneLinkController.otpLength) onVerify();
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: l10n.verify,
          loading: state.stage == PhoneLinkStage.verifying,
          onPressed: onVerify,
        ),
        const SizedBox(height: AppSpacing.sm),
        // Resend is gated by the cooldown; the countdown doubles as the code's
        // expiry hint.
        state.canResend
            ? TextButton(
                onPressed: state.isBusy ? null : onResend,
                child: Text(l10n.resendCode),
              )
            : Text(
                l10n.otpResendIn(_countdown(state.resendSeconds)),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
      ],
    );
  }
}

/// Selected country's flag + dial code beside the number field.
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
