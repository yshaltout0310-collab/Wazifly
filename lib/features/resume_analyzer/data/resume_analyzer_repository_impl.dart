import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/ai/ai_exception.dart';
import '../../../core/services/ai/ai_providers.dart';
import '../../../core/services/ai/ai_service.dart';
import '../domain/pdf_text_extractor.dart';
import '../domain/resume_analysis.dart';
import '../domain/resume_analyzer_exception.dart';
import '../domain/resume_analyzer_repository.dart';
import 'syncfusion_pdf_text_extractor.dart';

/// Orchestrates the resume-analysis pipeline: extract text from the PDF, ask
/// the [AiService] for a structured JSON assessment, and map it to a
/// [ResumeAnalysis]. Depends only on the [AiService] and [PdfTextExtractor]
/// abstractions, so the AI provider and PDF library are both swappable.
class ResumeAnalyzerRepositoryImpl implements ResumeAnalyzerRepository {
  ResumeAnalyzerRepositoryImpl({
    required AiService ai,
    PdfTextExtractor? extractor,
  })  : _ai = ai,
        _extractor = extractor ?? const SyncfusionPdfTextExtractor();

  final AiService _ai;
  final PdfTextExtractor _extractor;

  /// Below this, the PDF almost certainly has no selectable text (scanned).
  static const int _minChars = 40;

  /// Cap the text sent to the model to keep the prompt bounded and cheap.
  static const int _maxChars = 20000;

  static const String _systemInstruction =
      'You are an expert ATS (Applicant Tracking System) analyst and senior '
      'career coach. You evaluate resumes objectively and give concise, '
      'honest, actionable feedback. You always respond with only valid JSON.';

  @override
  Future<ResumeAnalysis> analyze({
    required Uint8List pdfBytes,
    required String languageCode,
    String? fileName,
  }) async {
    final text = (await _extractor.extract(pdfBytes)).trim();
    if (text.length < _minChars) {
      throw const ResumeAnalyzerException(ResumeErrorCode.noText);
    }

    final clipped = text.length > _maxChars ? text.substring(0, _maxChars) : text;
    final json = await _ai.generateJson(
      _buildPrompt(clipped, languageCode),
      systemInstruction: _systemInstruction,
    );

    final analysis = ResumeAnalysis.fromJson(json);
    if (analysis.isEmpty) {
      throw const AiException(AiErrorCode.invalidResponse);
    }
    return analysis;
  }

  String _buildPrompt(String resumeText, String languageCode) {
    final language = languageCode == 'ar' ? 'Arabic' : 'English';
    return '''
Analyze the following resume and return a JSON object with EXACTLY these keys:
- "atsScore": integer 0-100 (ATS compatibility and overall quality)
- "summary": a one or two sentence overall assessment
- "strengths": array of short strings
- "weaknesses": array of short strings
- "missingSkills": array of in-demand skills or keywords the resume should add for its target roles
- "grammarIssues": array of objects, each { "issue": short description, "suggestion": the concrete fix }
- "improvementSuggestions": array of concrete, actionable suggestions

Rules:
- Write ALL text values in $language.
- Be specific and concise; prefer 3 to 6 items per array.
- Base everything only on the resume content below.
- Return ONLY the JSON object — no markdown, no commentary.

Resume:
"""
$resumeText
"""''';
  }
}

/// The app-wide resume analyzer repository (uses the bound [aiServiceProvider]).
final resumeAnalyzerRepositoryProvider = Provider<ResumeAnalyzerRepository>(
  (ref) => ResumeAnalyzerRepositoryImpl(ai: ref.watch(aiServiceProvider)),
);
