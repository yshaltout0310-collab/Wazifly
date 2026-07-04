import '../../resume_analyzer/domain/resume_analysis.dart';
import 'cv_data.dart';

/// Uses AI to strengthen a [CvData]: a tailored professional summary,
/// achievement-focused experience bullets, and a clean skills list — reusing a
/// prior [ResumeAnalysis] when available. The concrete implementation depends
/// only on the provider-agnostic `AiService`.
abstract interface class CvEnhancementRepository {
  /// Returns an enhanced copy of [data]. Non-content fields (names, employers,
  /// dates, education) are preserved verbatim; only summary/bullets/skills are
  /// rewritten. Throws [CvBuilderException] on an unusable AI response.
  Future<CvData> enhance(
    CvData data, {
    required String languageCode,
    ResumeAnalysis? analysis,
  });
}
