/// Stable, backend-agnostic error codes for the recruiter-insights pipeline.
enum RecruiterInsightsErrorCode {
  /// The AI returned no usable insights in any section.
  emptyInsights,
}

/// Raised by the recruiter-insights repository; carries a stable [code] the
/// presentation layer maps to a localized message. AI-provider failures still
/// surface as [AiException] and are mapped by the controller.
class RecruiterInsightsException implements Exception {
  const RecruiterInsightsException(this.code, [this.rawMessage]);

  final RecruiterInsightsErrorCode code;
  final String? rawMessage;

  @override
  String toString() =>
      'RecruiterInsightsException(${code.name}): $rawMessage';
}
