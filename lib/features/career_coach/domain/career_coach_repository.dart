import '../../resume_analyzer/domain/resume_analysis.dart';
import 'chat_message.dart';

/// Streams the Career Coach's reply for a conversation.
///
/// Feature code depends on this interface only; the implementation builds the
/// coach persona (optionally personalized with [resume]) and delegates to the
/// `AiService`'s multi-turn streaming.
abstract interface class CareerCoachRepository {
  /// Streams the assistant's reply to [history] (the last entry is the user's
  /// latest message). [languageCode] (`en`/`ar`) asks the model to reply in the
  /// user's language. When [resume] is non-null, the coach tailors its advice to
  /// that analyzed resume.
  ///
  /// Yields text chunks as they arrive; throws `AiException` on failure.
  Stream<String> reply({
    required List<ChatMessage> history,
    required String languageCode,
    ResumeAnalysis? resume,
    String? country,
  });
}
