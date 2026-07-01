import 'dart:typed_data';

import 'resume_analysis.dart';

/// Analyzes a resume end-to-end (extract text → AI analysis → structured
/// result). Feature code depends on this interface only.
abstract interface class ResumeAnalyzerRepository {
  /// Analyzes the resume PDF in [pdfBytes].
  ///
  /// [languageCode] (`en` / `ar`) asks the model to return the feedback in the
  /// user's language. [fileName] is used only for diagnostics/logging.
  ///
  /// Throws `ResumeAnalyzerException` if no text can be extracted and
  /// `AiException` if the AI call fails or returns an unusable result.
  Future<ResumeAnalysis> analyze({
    required Uint8List pdfBytes,
    required String languageCode,
    String? fileName,
  });
}
