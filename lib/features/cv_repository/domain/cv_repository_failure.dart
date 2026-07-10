/// UI-facing, localizable failure categories for CV-repository actions.
enum CvActionFailure {
  /// Blocked: the user must keep at least one active CV (default protection).
  lastActiveCv,

  /// Import: the AI backend isn't configured.
  notConfigured,

  /// Import: no text could be extracted from the PDF (e.g. a scan).
  importNoText,

  /// Import: reading/extracting the file failed.
  importFailed,

  network,
  quota,
  invalidResponse,
  unknown,
}
