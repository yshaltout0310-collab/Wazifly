/// AI service abstraction (architecture only — no implementation in Phase 1).
///
/// Defining the contract now lets the whole app depend on the *interface*
/// rather than a concrete vendor. The Gemini implementation (and any future
/// provider) can be slotted in later without touching feature code.
abstract interface class AiService {
  /// Analyzes resume text and returns structured feedback.
  Future<String> analyzeResume(String resumeText);

  /// Generates career coaching guidance for a free-form prompt.
  Future<String> careerCoach(String prompt);

  /// Produces interview preparation material for a given role.
  Future<String> prepareInterview({required String role});
}

/// Placeholder Gemini-backed implementation.
///
/// Intentionally unimplemented in Phase 1. When wired up it will call the
/// Gemini API (via `google_generative_ai` or REST) using a key injected from
/// secure config — never hard-coded.
class GeminiAiService implements AiService {
  GeminiAiService({this.apiKey});

  final String? apiKey;

  static const String _todo =
      'Gemini integration is prepared but not implemented in Phase 1.';

  @override
  Future<String> analyzeResume(String resumeText) =>
      throw UnimplementedError(_todo);

  @override
  Future<String> careerCoach(String prompt) =>
      throw UnimplementedError(_todo);

  @override
  Future<String> prepareInterview({required String role}) =>
      throw UnimplementedError(_todo);
}
