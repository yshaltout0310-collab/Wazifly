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
  /// Defined now so the Career Coach (Milestone 3) can render tokens as they
  /// arrive without changing the contract.
  Stream<String> streamText(String prompt, {String? systemInstruction});
}
