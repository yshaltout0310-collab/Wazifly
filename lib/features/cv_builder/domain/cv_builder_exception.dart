/// Stable, backend-agnostic error codes for the CV Builder pipeline.
enum CvErrorCode {
  /// The chosen template isn't implemented yet (a "coming soon" template).
  templateUnavailable,

  /// PDF generation failed (font load / rendering).
  generationFailed,

  /// The AI returned nothing usable to enhance the CV with.
  emptyEnhancement,
}

/// Raised by the CV Builder repositories/generator; carries a stable [code] the
/// presentation layer maps to a localized message.
class CvBuilderException implements Exception {
  const CvBuilderException(this.code, [this.rawMessage]);

  final CvErrorCode code;
  final String? rawMessage;

  @override
  String toString() => 'CvBuilderException(${code.name}): $rawMessage';
}
