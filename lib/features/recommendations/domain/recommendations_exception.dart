/// Stable, backend-agnostic error codes for the recommendations pipeline.
enum RecErrorCode {
  /// The AI returned no usable recommendations in any section.
  emptyRecommendations,
}

/// Raised by the recommendations repository; carries a stable [code] the
/// presentation layer maps to a localized message. AI-provider failures still
/// surface as [AiException] and are mapped by the controller.
class RecommendationsException implements Exception {
  const RecommendationsException(this.code, [this.rawMessage]);

  final RecErrorCode code;
  final String? rawMessage;

  @override
  String toString() => 'RecommendationsException(${code.name}): $rawMessage';
}
