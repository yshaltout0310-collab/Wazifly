/// Stable, backend-agnostic error codes for the interview pipeline.
enum InterviewErrorCode {
  /// The AI returned no usable questions.
  noQuestions,

  /// The AI returned nothing usable to evaluate the answer with.
  emptyEvaluation,
}

/// Raised by the interview repository; carries a stable [code] the presentation
/// layer maps to a localized message. AI-provider failures still surface as
/// [AiException] and are mapped by the controller.
class InterviewException implements Exception {
  const InterviewException(this.code, [this.rawMessage]);

  final InterviewErrorCode code;
  final String? rawMessage;

  @override
  String toString() => 'InterviewException(${code.name}): $rawMessage';
}
