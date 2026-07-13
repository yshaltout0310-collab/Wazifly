import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_controller.dart';
import '../../country_selection/application/country_controller.dart';
import '../../../core/services/ai/ai_exception.dart';
import '../../../core/services/chat_store/chat_history_store.dart';
import '../../../core/services/resume_store/resume_analysis_store.dart';
import '../data/career_coach_repository_impl.dart';
import '../domain/chat_message.dart';

/// UI-facing, localizable failure categories for the coach.
enum CoachFailure {
  notConfigured,
  network,
  quota,
  blocked,
  emptyResponse,
  unknown,
}

/// Immutable state for the career coach screen.
class CareerCoachState extends Equatable {
  const CareerCoachState({
    this.messages = const [],
    this.isStreaming = false,
    this.failure,
  });

  final List<ChatMessage> messages;
  final bool isStreaming;

  /// A transient failure to surface (e.g. via snackbar); the failed reply is
  /// also marked in [messages].
  final CoachFailure? failure;

  bool get isEmpty => messages.isEmpty;

  CareerCoachState copyWith({
    List<ChatMessage>? messages,
    bool? isStreaming,
    CoachFailure? failure,
    bool clearFailure = false,
  }) =>
      CareerCoachState(
        messages: messages ?? this.messages,
        isStreaming: isStreaming ?? this.isStreaming,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [messages, isStreaming, failure];
}

/// Drives the Career Coach chat: appends the user's message, streams the
/// assistant's reply token-by-token, and persists history via the store seam.
/// Personalizes replies with the cached resume analysis when available.
class CareerCoachController extends StateNotifier<CareerCoachState> {
  CareerCoachController(this._ref)
      : super(CareerCoachState(
          messages: _ref.read(chatHistoryStoreProvider).read(),
        ));

  /// Test-only: start from a specific state without touching the store.
  @visibleForTesting
  CareerCoachController.seeded(this._ref, CareerCoachState initial)
      : super(initial);

  final Ref _ref;

  StreamSubscription<String>? _sub;
  int _seq = 0;
  String? _streamingId;

  String _nextId() => 'm${_seq++}';

  /// Sends [text] as a user message and streams the coach's reply.
  ///
  /// Ignored while a reply is already streaming or when [text] is blank.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isStreaming) return;

    final userMsg = ChatMessage(
      id: _nextId(),
      role: ChatRole.user,
      text: trimmed,
    );
    final assistantId = _nextId();
    final placeholder = ChatMessage(
      id: assistantId,
      role: ChatRole.assistant,
      text: '',
      status: ChatMessageStatus.streaming,
    );

    // History sent to the model includes the new user turn, not the empty
    // assistant placeholder.
    final history = [...state.messages, userMsg];
    _streamingId = assistantId;
    state = state.copyWith(
      messages: [...history, placeholder],
      isStreaming: true,
      clearFailure: true,
    );

    final languageCode =
        _ref.read(localeControllerProvider)?.languageCode ?? 'en';
    final resume = _ref.read(lastResumeAnalysisProvider);
    final country = _ref.read(countryControllerProvider)?.name;

    await _sub?.cancel();
    _sub = _ref.read(careerCoachRepositoryProvider).reply(
          history: history,
          languageCode: languageCode,
          resume: resume,
          country: country,
        ).listen(
          _onChunk,
          onError: _onError,
          onDone: _onDone,
          cancelOnError: true,
        );
  }

  void _onChunk(String chunk) {
    if (!mounted) return;
    _updateStreaming((m) => m.copyWith(text: m.text + chunk));
  }

  void _onDone() {
    if (!mounted) return;
    _updateStreaming((m) => m.copyWith(
          // An empty reply that never errored is treated as a failure.
          status: m.text.isEmpty
              ? ChatMessageStatus.failed
              : ChatMessageStatus.complete,
        ));
    final failedEmpty = state.messages
        .any((m) => m.id == _streamingId && m.status == ChatMessageStatus.failed);
    _streamingId = null;
    state = state.copyWith(
      isStreaming: false,
      failure: failedEmpty ? CoachFailure.emptyResponse : null,
      clearFailure: !failedEmpty,
    );
    _persist();
  }

  void _onError(Object error, StackTrace _) {
    if (!mounted) return;
    _updateStreaming((m) => m.copyWith(status: ChatMessageStatus.failed));
    _streamingId = null;
    state = state.copyWith(isStreaming: false, failure: _mapFailure(error));
    _persist();
  }

  /// Replaces the currently streaming assistant message via [update].
  void _updateStreaming(ChatMessage Function(ChatMessage) update) {
    final id = _streamingId;
    if (id == null) return;
    state = state.copyWith(
      messages: [
        for (final m in state.messages) m.id == id ? update(m) : m,
      ],
    );
  }

  /// Clears the whole conversation.
  Future<void> clearChat() async {
    await _sub?.cancel();
    _sub = null;
    _streamingId = null;
    state = const CareerCoachState();
    await _ref.read(chatHistoryStoreProvider).clear();
  }

  /// Retries after a failed reply: drops the failed assistant turn and resends
  /// the last user message.
  Future<void> retryLast() async {
    if (state.isStreaming || state.messages.isEmpty) return;
    final msgs = [...state.messages];
    if (msgs.last.role == ChatRole.assistant) {
      msgs.removeLast();
    }
    if (msgs.isEmpty || msgs.last.role != ChatRole.user) return;
    final lastUser = msgs.removeLast();
    state = state.copyWith(messages: msgs, clearFailure: true);
    await sendMessage(lastUser.text);
  }

  void _persist() {
    // Persist only settled conversations (no in-flight streaming message).
    if (state.isStreaming) return;
    _ref.read(chatHistoryStoreProvider).write(state.messages);
  }

  CoachFailure _mapFailure(Object e) {
    if (e is AiException) {
      return switch (e.code) {
        AiErrorCode.notConfigured => CoachFailure.notConfigured,
        AiErrorCode.network => CoachFailure.network,
        AiErrorCode.quota => CoachFailure.quota,
        AiErrorCode.blocked => CoachFailure.blocked,
        AiErrorCode.emptyResponse => CoachFailure.emptyResponse,
        AiErrorCode.invalidResponse || AiErrorCode.unknown => CoachFailure.unknown,
      };
    }
    debugPrint('[CareerCoach] unmapped error: $e');
    return CoachFailure.unknown;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final careerCoachControllerProvider =
    StateNotifierProvider<CareerCoachController, CareerCoachState>(
  CareerCoachController.new,
);
