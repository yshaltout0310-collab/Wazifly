import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/ai/ai_exception.dart';
import '../../../core/services/ai/ai_providers.dart';
import '../../../core/services/ai/ai_service.dart';
import '../domain/pdf_text_extractor.dart';
import '../domain/resume_analysis.dart';
import '../domain/resume_analyzer_exception.dart';
import '../domain/resume_analyzer_repository.dart';
import '../domain/resume_ocr.dart';
import 'gemini_pdf_ocr.dart';
import 'syncfusion_pdf_text_extractor.dart';

/// Orchestrates the resume-analysis pipeline: extract text from the PDF, ask
/// the [AiService] for a structured JSON assessment, and map it to a
/// [ResumeAnalysis]. Depends only on the [AiService], [PdfTextExtractor], and
/// [ResumeOcr] abstractions, so the AI provider, PDF library, and OCR backend
/// are all swappable.
class ResumeAnalyzerRepositoryImpl implements ResumeAnalyzerRepository {
  ResumeAnalyzerRepositoryImpl({
    required AiService ai,
    PdfTextExtractor? extractor,
    ResumeOcr? ocr,
  })  : _ai = ai,
        _extractor = extractor ?? const SyncfusionPdfTextExtractor(),
        _ocr = ocr;

  final AiService _ai;
  final PdfTextExtractor _extractor;

  /// Optional OCR fallback for scanned/image-only PDFs. When null, an
  /// image-only PDF surfaces the usual "no text" error (legacy behavior).
  final ResumeOcr? _ocr;

  /// Below this, the PDF almost certainly has no selectable text (scanned).
  static const int _minChars = 40;

  /// Cap the text sent to the model to keep the prompt bounded and cheap.
  static const int _maxChars = 20000;

  static const String _systemInstruction =
      'You are an expert ATS (Applicant Tracking System) analyst and senior '
      'career coach who reviews resumes across every profession (software, '
      'engineering, healthcare, finance, design, marketing, trades, academia, '
      'and more). You FIRST identify the candidate\'s own career field from '
      'their resume, then evaluate strictly within that field. You never judge '
      'a candidate against a profession they are not pursuing, and you never '
      'recommend skills from an unrelated domain. You are objective, concise, '
      'and honest. You always respond with only valid JSON.';

  @override
  Future<ResumeAnalysis> analyze({
    required Uint8List pdfBytes,
    required String languageCode,
    String? fileName,
  }) async {
    var text = (await _extractor.extract(pdfBytes)).trim();
    if (text.length < _minChars) {
      // No usable text layer — the PDF is almost certainly a scan (Adobe Scan,
      // CamScanner, Microsoft Lens, a photographed page). Fall back to OCR and
      // continue the analysis with whatever text it recovers. If OCR is
      // unavailable or also comes up empty, surface the usual "no text" error.
      final ocrText = (await _ocr?.extractText(pdfBytes))?.trim() ?? '';
      if (ocrText.length < _minChars) {
        throw const ResumeAnalyzerException(ResumeErrorCode.noText);
      }
      text = ocrText;
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
    final today = _todayIso();
    return '''
You will analyze ONE resume and return a single JSON object.

STEP 1 — IDENTIFY THE FIELD (do this before anything else):
Read the whole resume and determine the candidate's ACTUAL primary career
field and their most likely target roles. Weigh the strongest evidence:
their stated title/objective, degree/major, technical skills, tools, projects,
and certifications carry the most weight. Do NOT be misled by generic
leadership, volunteering, or soft-skill wording that appears in resumes from
every field. Examples of fields: Software / Computer Science, Cybersecurity &
Networking, Data Science, Mechanical Engineering, Nursing, Accounting &
Finance, Marketing, Graphic Design, Sales, Teaching, etc. Put your conclusion
in "careerField" as a short label (optionally "Field — target role").

STEP 2 — EVALUATE WITHIN THAT FIELD ONLY:
Judge the resume ONLY against the norms and expectations of the "careerField"
you identified. Everything you output must be relevant to that field.
- "missingSkills" MUST be skills/tools/keywords that matter for THAT field's
  target roles. NEVER suggest skills from an unrelated domain (e.g. do NOT
  recommend accounting, ERP/SAP, sales, or bookkeeping skills to a software /
  computer-science candidate; do NOT recommend programming languages to a
  nurse). If you cannot justify a skill for this candidate's field, omit it.
- "weaknesses" and "improvementSuggestions" must likewise fit the field.

SCORING RUBRIC — "atsScore" is an integer 0-100. Start from 100 and deduct;
weight the dimensions roughly as:
- Relevant skills & keywords for the target field (25)
- Clear, quantified impact / results in experience (20)
- Structure, standard ATS-parsable sections & formatting (20)
- Education / certifications relevant to the field (15)
- Writing quality: grammar, concision, consistency (10)
- Contact info & completeness (10)
Bands: 85-100 excellent, 70-84 strong, 55-69 fair, 40-54 weak, <40 poor.
CALIBRATE TO CAREER STAGE: judge the resume against realistic expectations for
the candidate's own level (student / entry-level / junior / mid / senior),
inferred from their experience. Do NOT penalize a student or entry-level
candidate for lacking things that stage cannot have (years of experience,
enterprise-scale quantified impact, senior leadership); score them against
strong peers at THEIR level. A solid, relevant, well-structured resume that is
appropriate for its field and stage should land in the 70-84 band. Do not be
needlessly harsh; reserve <55 for resumes with real, specific, material gaps.

DATE VALIDATION — today's date is $today.
Resume dates are commonly written as "MMM YYYY" (Jan 2026), "YYYY", ranges
("2023 – 2025"), or open ranges ("2025 – Present"). Treat any plausibly
formatted and logically ordered date as VALID. Only raise a date issue when it
is genuinely impossible — e.g. an end date before its start date, or claimed
work experience dated clearly beyond today. Do NOT invent date problems and do
NOT flag a normal, well-formed date as an error.

OUTPUT — return a JSON object with EXACTLY these keys:
- "careerField": short string naming the field you identified in STEP 1
- "atsScore": integer 0-100 per the rubric above
- "summary": one or two sentences; mention the identified field
- "strengths": array of short strings
- "weaknesses": array of short strings
- "missingSkills": array of field-relevant skills/keywords to add
- "grammarIssues": array of objects, each { "issue": short description, "suggestion": the concrete fix }
- "improvementSuggestions": array of concrete, actionable suggestions

Rules:
- Write ALL text values in $language (keep the field label meaningful).
- Be specific and concise; prefer 3 to 6 items per array.
- Base everything ONLY on the resume content below — do not assume a field the
  evidence does not support.
- Return ONLY the JSON object — no markdown, no commentary.

Resume:
"""
$resumeText
"""''';
  }

  /// Today's date as ISO `YYYY-MM-DD`, used to ground the model's date checks.
  static String _todayIso() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }
}

/// The app-wide resume analyzer repository (uses the bound [aiServiceProvider]
/// and a Gemini-vision OCR fallback for scanned PDFs).
final resumeAnalyzerRepositoryProvider = Provider<ResumeAnalyzerRepository>(
  (ref) => ResumeAnalyzerRepositoryImpl(
    ai: ref.watch(aiServiceProvider),
    ocr: GeminiPdfOcr(),
  ),
);
