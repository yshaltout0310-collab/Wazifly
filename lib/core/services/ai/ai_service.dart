import 'ai_message.dart';

/// Provider-agnostic AI abstraction used across every AI feature (resume
/// analysis, job matching, career coach).
///
/// Feature code depends only on this interface — never on a concrete vendor —
/// so the provider (Firebase AI Logic / Gemini today, anything tomorrow) can be
/// swapped by changing a single Riverpod binding in `ai_providers.dart`.
///
/// All methods throw [AiException] (see `ai_exception.dart`) with a stable,
/// localizable error code on failure.
abstract interface class AiService {
  // Note: `AiMessage`/`AiRole` (see `ai_message.dart`) are plain value types, so
  // even the multi-turn chat contract keeps vendor types out of the interface.
  /// Generates free-form text for [prompt].
  ///
  /// [systemInstruction] optionally sets the model's role/behaviour.
  Future<String> generateText(String prompt, {String? systemInstruction});

  /// Generates a structured JSON object for [prompt] and returns it decoded.
  ///
  /// The implementation constrains the model to emit valid JSON; the [prompt]
  /// is responsible for describing the exact keys/shape expected. Callers should
  /// still parse defensively (the model may omit optional fields).
  Future<Map<String, dynamic>> generateJson(
    String prompt, {
    String? systemInstruction,
  });

  /// Streams text for [prompt] as it is generated.
  ///
  /// Single-shot (no conversation memory). For multi-turn chat use [streamChat].
  Stream<String> streamText(String prompt, {String? systemInstruction});

  /// Streams the model's reply to a multi-turn conversation.
  ///
  /// [history] is the full ordered turn list (user + model), the last entry
  /// being the message to respond to. [systemInstruction] sets the assistant's
  /// role/persona. Tokens are yielded as they arrive so the UI can render the
  /// reply incrementally. Powers the Career Coach (Milestone 3).
  Stream<String> streamChat(
    List<AiMessage> history, {
    String? systemInstruction,
  });
}
