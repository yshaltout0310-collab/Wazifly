import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/services/ai/ai_exception.dart';
import '../data/interview_kit_repository_impl.dart';
import '../domain/interview_kit.dart';

/// Generation lifecycle for the employer interview-kit tool.
enum InterviewKitPhase { idle, loading, ready, error }

/// UI-facing, localizable failure categories (mirrors `RecruiterInsightsFailure`).
enum InterviewKitFailure {
  notConfigured,
  network,
  quota,
  invalidResponse,
  empty,
  unknown,
}

class InterviewKitState extends Equatable {
  const InterviewKitState({
    this.phase = InterviewKitPhase.idle,
    this.kit,
    this.failure,
  });

  final InterviewKitPhase phase;
  final InterviewKit? kit;
  final InterviewKitFailure? failure;

  bool get isLoading => phase == InterviewKitPhase.loading;

  InterviewKitState copyWith({
    InterviewKitPhase? phase,
    InterviewKit? kit,
    InterviewKitFailure? failure,
    bool clearFailure = false,
  }) =>
      InterviewKitState(
        phase: phase ?? this.phase,
        kit: kit ?? this.kit,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [phase, kit, failure];
}

/// Drives the AI interview-kit generator: builds a localized request from the
/// employer's role/focus input, calls the repository, and maps failures to a
/// localizable category. On-demand (starts [idle]).
class InterviewKitController extends StateNotifier<InterviewKitState> {
  InterviewKitController(this._ref) : super(const InterviewKitState());

  final Ref _ref;

  String get _languageCode =>
      _ref.read(localeControllerProvider)?.languageCode ?? 'en';

  Future<void> generate(String role, {String focus = ''}) async {
    state = state.copyWith(
        phase: InterviewKitPhase.loading, clearFailure: true);
    try {
      final kit = await _ref.read(interviewKitRepositoryProvider).generate(
            role: role.trim(),
            focus: focus.trim(),
            languageCode: _languageCode,
          );
      if (!mounted) return;
      state = InterviewKitState(phase: InterviewKitPhase.ready, kit: kit);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
          phase: InterviewKitPhase.error, failure: _mapFailure(e));
    }
  }

  InterviewKitFailure _mapFailure(Object e) {
    if (e is InterviewKitException) return InterviewKitFailure.empty;
    if (e is AiException) {
      return switch (e.code) {
        AiErrorCode.notConfigured => InterviewKitFailure.notConfigured,
        AiErrorCode.network => InterviewKitFailure.network,
        AiErrorCode.quota => InterviewKitFailure.quota,
        AiErrorCode.emptyResponse ||
        AiErrorCode.invalidResponse =>
          InterviewKitFailure.invalidResponse,
        _ => InterviewKitFailure.unknown,
      };
    }
    debugPrint('[InterviewKit] failed: $e');
    return InterviewKitFailure.unknown;
  }
}

final interviewKitControllerProvider =
    StateNotifierProvider<InterviewKitController, InterviewKitState>(
  InterviewKitController.new,
);
