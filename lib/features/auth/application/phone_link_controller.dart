import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_repository.dart';
import 'auth_providers.dart';

/// Stages of the phone-verification (link) flow.
enum PhoneLinkStage { enterNumber, sendingCode, enterCode, verifying, linked }

/// Pre-submit validation reasons (distinct from backend auth errors).
enum PhoneLinkFailure { emptyNumber, invalidCode }

class PhoneLinkState extends Equatable {
  const PhoneLinkState({
    this.stage = PhoneLinkStage.enterNumber,
    this.verificationId,
    this.phoneNumber,
    this.resendSeconds = 0,
    this.error,
    this.localFailure,
  });

  final PhoneLinkStage stage;
  final String? verificationId;
  final String? phoneNumber;

  /// Seconds until "Resend" is allowed again (0 ⇒ allowed). Doubles as the
  /// visible code-expiry countdown.
  final int resendSeconds;

  /// A thrown backend error, resolved via `localizedAuthMessage`.
  final Object? error;

  /// A local validation failure (localized by the screen).
  final PhoneLinkFailure? localFailure;

  bool get canResend => resendSeconds == 0;
  bool get isBusy =>
      stage == PhoneLinkStage.sendingCode || stage == PhoneLinkStage.verifying;

  PhoneLinkState copyWith({
    PhoneLinkStage? stage,
    String? verificationId,
    String? phoneNumber,
    int? resendSeconds,
    Object? error,
    PhoneLinkFailure? localFailure,
    bool clearError = false,
    bool clearFailure = false,
  }) =>
      PhoneLinkState(
        stage: stage ?? this.stage,
        verificationId: verificationId ?? this.verificationId,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        resendSeconds: resendSeconds ?? this.resendSeconds,
        error: clearError ? null : (error ?? this.error),
        localFailure: clearFailure ? null : (localFailure ?? this.localFailure),
      );

  @override
  List<Object?> get props =>
      [stage, verificationId, phoneNumber, resendSeconds, error, localFailure];
}

/// Drives the phone-verification (link) state machine: send code → enter code →
/// link, with a resend cooldown / expiry countdown. Links the number to the
/// signed-in account via [AuthRepository] — never a phone-only sign-in.
class PhoneLinkController extends StateNotifier<PhoneLinkState> {
  PhoneLinkController(this._ref) : super(const PhoneLinkState());

  final Ref _ref;
  Timer? _timer;

  static const int otpLength = 6;

  /// Resend cooldown in seconds (also the visible expiry countdown).
  static const int resendCooldown = 60;

  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  Future<void> sendCode(String phoneNumber) async {
    final trimmed = phoneNumber.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(
          localFailure: PhoneLinkFailure.emptyNumber, clearError: true);
      return;
    }
    state = state.copyWith(
      stage: PhoneLinkStage.sendingCode,
      phoneNumber: trimmed,
      clearError: true,
      clearFailure: true,
    );
    await _repo.verifyPhoneForLink(
      phoneNumber: trimmed,
      onCodeSent: (vid) {
        if (!mounted) return;
        state =
            state.copyWith(stage: PhoneLinkStage.enterCode, verificationId: vid);
        _startCooldown();
      },
      onFailed: (e) {
        if (!mounted) return;
        _timer?.cancel();
        state = state.copyWith(stage: PhoneLinkStage.enterNumber, error: e);
      },
      onAutoLinked: (_) {
        if (!mounted) return;
        _timer?.cancel();
        state = state.copyWith(stage: PhoneLinkStage.linked);
      },
    );
  }

  Future<void> resend() async {
    final phone = state.phoneNumber;
    if (phone == null || !state.canResend) return;
    await sendCode(phone);
  }

  /// Verifies the entered [code] and links it. Returns true on success.
  Future<bool> submitCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.length != otpLength) {
      state = state.copyWith(
          localFailure: PhoneLinkFailure.invalidCode, clearError: true);
      return false;
    }
    final vid = state.verificationId;
    if (vid == null) return false;

    state = state.copyWith(
        stage: PhoneLinkStage.verifying, clearError: true, clearFailure: true);
    try {
      await _repo.confirmAndLinkSmsCode(verificationId: vid, smsCode: trimmed);
      if (!mounted) return true;
      _timer?.cancel();
      state = state.copyWith(stage: PhoneLinkStage.linked);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(stage: PhoneLinkStage.enterCode, error: e);
      return false;
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    state = state.copyWith(resendSeconds: resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final next = state.resendSeconds - 1;
      if (next <= 0) {
        t.cancel();
        state = state.copyWith(resendSeconds: 0);
      } else {
        state = state.copyWith(resendSeconds: next);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final phoneLinkControllerProvider =
    StateNotifierProvider.autoDispose<PhoneLinkController, PhoneLinkState>(
  PhoneLinkController.new,
);
