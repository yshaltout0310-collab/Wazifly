import 'interview_context.dart';
import 'interview_models.dart';

/// The AI operations behind the interview flow. Provider-agnostic — the
/// implementation depends only on the `AiService` abstraction — and pure (it
/// takes an [InterviewContext] rather than reading providers), so it is fully
/// unit-testable with a fake `AiService`.
abstract interface class InterviewRepository {
  /// Generates [count] interview questions of [type], tailored to [context].
  /// Uses structured JSON (no streaming). Throws [InterviewException] /
  /// [AiException] on failure.
  Future<List<InterviewQuestion>> generateQuestions({
    required InterviewType type,
    required InterviewContext context,
    required int count,
    required String languageCode,
  });

  /// Evaluates one [answer] to [question], returning 5-dimension scores +
  /// qualitative feedback. Structured JSON (reliable scores).
  Future<AnswerFeedback> evaluateAnswer({
    required InterviewType type,
    required InterviewQuestion question,
    required String answer,
    required InterviewContext context,
    required String languageCode,
  });

  /// Structured overall scorecard for the whole [session]: aggregate scores,
  /// key strengths, improvement suggestions, and an actionable improvement plan.
  /// The narrative prose is produced separately by [streamDebrief].
  Future<InterviewSummary> summarize({
    required InterviewSession session,
    required String languageCode,
  });

  /// Streams the warm, narrative overall debrief for [session] token-by-token
  /// (the one place streaming improves UX — mirrors the Career Coach).
  Stream<String> streamDebrief({
    required InterviewSession session,
    required String languageCode,
  });
}
