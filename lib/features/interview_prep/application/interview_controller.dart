import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/services/ai/ai_exception.dart';
import '../../../core/services/cv_store/cv_draft_store.dart';
import '../../../core/services/interview_store/in_memory_interview_history_repository.dart';
import '../../../core/services/resume_store/resume_analysis_store.dart';
import '../../../shared/models/job.dart';
import '../../profile/application/profile_completion_provider.dart';
import '../data/interview_repository_impl.dart';
import '../domain/interview_context.dart';
import '../domain/interview_exception.dart';
import '../domain/interview_models.dart';

enum InterviewPhase { setup, generating, inProgress, summarizing, summary, error }

/// UI-facing, localizable failure categories.
enum InterviewFailure {
  notConfigured,
  network,
  quota,
  invalidResponse,
  noQuestions,
  emptyEvaluation,
  unknown,
}

class InterviewState extends Equatable {
  const InterviewState({
    this.phase = InterviewPhase.setup,
    this.type = InterviewType.hr,
    this.context = const InterviewContext(),
    this.session,
    this.currentIndex = 0,
    this.isEvaluating = false,
    this.debrief = '',
    this.isStreamingDebrief = false,
    this.failure,
  });

  final InterviewPhase phase;
  final InterviewType type;
  final InterviewContext context;
  final InterviewSession? session;
  final int currentIndex;
  final bool isEvaluating;
  final String debrief;
  final bool isStreamingDebrief;
  final InterviewFailure? failure;

  List<InterviewQuestion> get questions => session?.questions ?? const [];

  InterviewQuestion? get currentQuestion =>
      (currentIndex >= 0 && currentIndex < questions.length)
          ? questions[currentIndex]
          : null;

  AnswerFeedback? get currentFeedback {
    final q = currentQuestion;
    return q == null ? null : session?.feedbackFor(q.id);
  }

  bool get hasAnsweredCurrent => currentFeedback != null;
  bool get isLastQuestion =>
      questions.isNotEmpty && currentIndex >= questions.length - 1;

  InterviewState copyWith({
    InterviewPhase? phase,
    InterviewType? type,
    InterviewContext? context,
    InterviewSession? session,
    int? currentIndex,
    bool? isEvaluating,
    String? debrief,
    bool? isStreamingDebrief,
    InterviewFailure? failure,
    bool clearFailure = false,
  }) =>
      InterviewState(
        phase: phase ?? this.phase,
        type: type ?? this.type,
        context: context ?? this.context,
        session: session ?? this.session,
        currentIndex: currentIndex ?? this.currentIndex,
        isEvaluating: isEvaluating ?? this.isEvaluating,
        debrief: debrief ?? this.debrief,
        isStreamingDebrief: isStreamingDebrief ?? this.isStreamingDebrief,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [
        phase,
        type,
        context,
        session,
        currentIndex,
        isEvaluating,
        debrief,
        isStreamingDebrief,
        failure,
      ];
}

/// Drives the interview flow: assemble a personalized [InterviewContext] from
/// core providers, generate questions, evaluate each answer, stream a final
/// debrief, and persist the completed session through the history seam.
class InterviewController extends StateNotifier<InterviewState> {
  InterviewController(this._ref, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(const InterviewState());

  /// Test-only: start in an explicit state.
  @visibleForTesting
  InterviewController.seeded(this._ref, InterviewState initial,
      {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(initial);

  final Ref _ref;
  final DateTime Function() _clock;

  StreamSubscription<String>? _sub;
  int _seq = 0;

  String get _languageCode =>
      _ref.read(localeControllerProvider)?.languageCode ?? 'en';

  /// Number of questions per interview.
  static const int questionCount = 5;

  /// Assembles the reuse context so the setup screen can preview personalization
  /// (called when the screen opens, optionally with a job).
  InterviewContext buildContext({InterviewType? type, Job? job}) {
    final profile = _ref.read(currentUserProfileProvider);
    final resume = _ref.read(lastResumeAnalysisProvider);
    final cv = _ref.read(cvDraftStoreProvider).read();

    final role = [
      job?.title,
      if (profile != null && profile.preferredJobTitles.isNotEmpty)
        profile.preferredJobTitles.first,
      profile?.headline,
      cv?.headline,
    ].firstWhere((e) => e != null && e.trim().isNotEmpty, orElse: () => '')!;

    final skills = <String>{
      ...?profile?.skills,
      ...?cv?.skills,
    }.toList();

    final cvExperiences = <String>[
      for (final e in cv?.experiences ?? const [])
        if (!e.isBlank)
          [e.role, e.company].where((s) => s.isNotEmpty).join(' — '),
    ].where((s) => s.isNotEmpty).toList();

    return InterviewContext(
      role: role.trim(),
      candidateName: profile?.displayName ?? '',
      headline: profile?.headline ?? '',
      experienceLevel: profile?.experienceLevel?.name ?? '',
      skills: skills,
      resumeSummary: resume?.summary ?? '',
      resumeStrengths: resume?.strengths ?? const [],
      resumeWeaknesses: resume?.weaknesses ?? const [],
      resumeMissingSkills: resume?.missingSkills ?? const [],
      cvExperiences: cvExperiences,
      jobTitle: job?.title ?? '',
      jobRequiredSkills: job?.requiredSkills ?? const [],
    );
  }

  /// Previews the personalization for the setup screen.
  void prepare({Job? job}) {
    state = state.copyWith(context: buildContext(job: job), clearFailure: true);
  }

  void selectType(InterviewType type) =>
      state = state.copyWith(type: type, clearFailure: true);

  /// Generates questions and starts the interview.
  Future<void> start({Job? job}) async {
    if (state.phase == InterviewPhase.generating) return;
    final type = state.type;
    final context = buildContext(job: job);
    state = state.copyWith(
      phase: InterviewPhase.generating,
      context: context,
      clearFailure: true,
    );
    try {
      final questions = await _ref.read(interviewRepositoryProvider).generateQuestions(
            type: type,
            context: context,
            count: questionCount,
            languageCode: _languageCode,
          );
      final session = InterviewSession.create(
        id: 'iv_${_clock().microsecondsSinceEpoch}_${_seq++}',
        type: type,
        role: context.role,
        jobId: job?.id,
        jobTitle: job?.title,
        questions: questions,
        now: _clock(),
      );
      state = state.copyWith(
        phase: InterviewPhase.inProgress,
        session: session,
        currentIndex: 0,
        clearFailure: true,
      );
    } catch (e) {
      _fail(e);
    }
  }

  /// Evaluates the current question's [answer] and stores the feedback.
  Future<void> submitAnswer(String answer) async {
    final session = state.session;
    final question = state.currentQuestion;
    if (session == null || question == null || state.isEvaluating) return;
    if (answer.trim().isEmpty) return;

    state = state.copyWith(isEvaluating: true, clearFailure: true);
    try {
      final fb = await _ref.read(interviewRepositoryProvider).evaluateAnswer(
            type: session.type,
            question: question,
            answer: answer,
            context: state.context,
            languageCode: _languageCode,
          );
      final updated = session.withAnswer(
        InterviewAnswer(questionId: question.id, text: answer.trim()),
        fb,
        _clock(),
      );
      state = state.copyWith(session: updated, isEvaluating: false);
    } catch (e) {
      state = state.copyWith(isEvaluating: false, failure: _mapFailure(e));
    }
  }

  /// Advances to the next question.
  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(
          currentIndex: state.currentIndex + 1, clearFailure: true);
    }
  }

  /// Finishes the interview: streams the debrief, fetches the structured
  /// scorecard, persists the completed session.
  Future<void> finish() async {
    final session = state.session;
    if (session == null || state.phase == InterviewPhase.summarizing) return;

    state = state.copyWith(
      phase: InterviewPhase.summarizing,
      debrief: '',
      isStreamingDebrief: true,
      clearFailure: true,
    );

    final lang = _languageCode;
    final buffer = StringBuffer();
    await _sub?.cancel();
    final completer = Completer<void>();
    _sub = _ref
        .read(interviewRepositoryProvider)
        .streamDebrief(session: session, languageCode: lang)
        .listen(
      (chunk) {
        if (!mounted) return;
        buffer.write(chunk);
        state = state.copyWith(debrief: buffer.toString());
      },
      onError: (Object e, StackTrace _) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );

    try {
      await completer.future;
      final scorecard = await _ref
          .read(interviewRepositoryProvider)
          .summarize(session: session, languageCode: lang);
      final summary = InterviewSummary(
        scores: scorecard.scores,
        overallFeedback: buffer.toString().trim(),
        keyStrengths: scorecard.keyStrengths,
        improvementSuggestions: scorecard.improvementSuggestions,
        improvementPlan: scorecard.improvementPlan,
      );
      final completed = session.completed(summary, _clock());
      await _ref
          .read(interviewHistoryRepositoryProvider)
          .saveSession(completed);
      if (!mounted) return;
      state = state.copyWith(
        phase: InterviewPhase.summary,
        session: completed,
        isStreamingDebrief: false,
        clearFailure: true,
      );
    } catch (e) {
      if (!mounted) return;
      _fail(e, streamingDebrief: false);
    }
  }

  /// Retries the failed step (generation or summary), else returns to setup.
  Future<void> retry() async {
    switch (state.phase) {
      case InterviewPhase.error when state.session == null:
        await start();
      case InterviewPhase.error:
        await finish();
      case _:
        reset();
    }
  }

  /// Discards the current interview and returns to the setup screen.
  void reset() {
    _sub?.cancel();
    _sub = null;
    state = InterviewState(type: state.type, context: state.context);
  }

  void clearFailure() => state = state.copyWith(clearFailure: true);

  void _fail(Object e, {bool streamingDebrief = false}) {
    debugPrint('[Interview] failed: $e');
    state = state.copyWith(
      phase: InterviewPhase.error,
      isStreamingDebrief: streamingDebrief,
      isEvaluating: false,
      failure: _mapFailure(e),
    );
  }

  InterviewFailure _mapFailure(Object e) {
    if (e is InterviewException) {
      return switch (e.code) {
        InterviewErrorCode.noQuestions => InterviewFailure.noQuestions,
        InterviewErrorCode.emptyEvaluation => InterviewFailure.emptyEvaluation,
      };
    }
    if (e is AiException) {
      return switch (e.code) {
        AiErrorCode.notConfigured => InterviewFailure.notConfigured,
        AiErrorCode.network => InterviewFailure.network,
        AiErrorCode.quota => InterviewFailure.quota,
        AiErrorCode.emptyResponse ||
        AiErrorCode.invalidResponse =>
          InterviewFailure.invalidResponse,
        _ => InterviewFailure.unknown,
      };
    }
    return InterviewFailure.unknown;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final interviewControllerProvider =
    StateNotifierProvider<InterviewController, InterviewState>(
  InterviewController.new,
);
