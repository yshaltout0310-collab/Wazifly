/// Errors from the resume-analysis pipeline that are *not* AI errors
/// (AI failures use `AiException`). Carries a stable, localizable [code].
enum ResumeErrorCode {
  /// No selectable text found — e.g. a scanned / image-only PDF.
  noText,

  /// The chosen file exceeds the allowed size.
  tooLarge,

  /// The PDF could not be parsed.
  extractionFailed,
}

class ResumeAnalyzerException implements Exception {
  const ResumeAnalyzerException(this.code, [this.rawMessage]);

  final ResumeErrorCode code;
  final String? rawMessage;

  @override
  String toString() => 'ResumeAnalyzerException(${code.name}): $rawMessage';
}
