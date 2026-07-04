import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/ai/ai_providers.dart';
import '../../../core/services/ai/ai_service.dart';
import '../../resume_analyzer/domain/resume_analysis.dart';
import '../domain/cv_builder_exception.dart';
import '../domain/cv_data.dart';
import '../domain/cv_enhancement_repository.dart';

/// Builds a localized prompt from the CV (plus an optional resume analysis),
/// asks the [AiService] for polished content as JSON, and merges it back into
/// the [CvData] — preserving all factual fields.
class CvEnhancementRepositoryImpl implements CvEnhancementRepository {
  CvEnhancementRepositoryImpl({required AiService ai}) : _ai = ai;

  final AiService _ai;

  static const String _system =
      'You are an expert resume writer and ATS (Applicant Tracking System) '
      'specialist. You improve CV wording to be concise, professional, and '
      'keyword-rich without ever inventing facts. You always respond with only '
      'valid JSON.';

  @override
  Future<CvData> enhance(
    CvData data, {
    required String languageCode,
    ResumeAnalysis? analysis,
  }) async {
    final json = await _ai.generateJson(
      _buildPrompt(data, languageCode, analysis),
      systemInstruction: _system,
    );
    final enhanced = _merge(data, json);
    // Nothing usable came back → surface an error rather than a silent no-op.
    if (enhanced == data) {
      throw const CvBuilderException(CvErrorCode.emptyEnhancement);
    }
    return enhanced;
  }

  CvData _merge(CvData data, Map<String, dynamic> json) {
    final summary = (json['summary'] ?? '').toString().trim();
    final skills = CvData.stringList(json['skills']);

    // Experiences: rewrite bullets by position; keep everything else.
    final rawExp = json['experiences'] ?? json['experience'];
    final experiences = <CvExperience>[];
    for (var i = 0; i < data.experiences.length; i++) {
      final original = data.experiences[i];
      List<String>? newBullets;
      if (rawExp is List && i < rawExp.length && rawExp[i] is Map) {
        final m = Map<String, dynamic>.from(rawExp[i] as Map);
        final b = CvData.stringList(m['bullets']);
        if (b.isNotEmpty) newBullets = b;
      }
      experiences.add(
        newBullets == null ? original : original.copyWith(bullets: newBullets),
      );
    }

    return data.copyWith(
      summary: summary.isNotEmpty ? summary : data.summary,
      skills: skills.isNotEmpty ? skills : data.skills,
      experiences: experiences,
    );
  }

  String _buildPrompt(
      CvData data, String languageCode, ResumeAnalysis? analysis) {
    final language = languageCode == 'ar' ? 'Arabic' : 'English';
    final target =
        data.targetRole.isNotEmpty ? data.targetRole : data.headline;

    // Compact input the model rewrites (only content it may rephrase).
    final input = jsonEncode({
      'name': data.fullName,
      'headline': data.headline,
      'summary': data.summary,
      'skills': data.skills,
      'experiences': [
        for (final e in data.experiences)
          {'role': e.role, 'company': e.company, 'bullets': e.bullets},
      ],
      'education': [
        for (final e in data.education)
          {'degree': e.degree, 'institution': e.institution},
      ],
    });

    final analysisBlock = analysis == null
        ? ''
        : '''

Insights from the candidate's prior resume analysis — leverage these:
- Overall assessment: ${analysis.summary}
- Strengths to emphasize: ${analysis.strengths.join('; ')}
- Skills/keywords to add IF truthful for this candidate: ${analysis.missingSkills.join('; ')}
- Improvement suggestions: ${analysis.improvementSuggestions.join('; ')}''';

    return '''
Improve the following CV content for the target role: "$target".

Rules:
- Write ALL text values in $language.
- Do NOT invent employers, job titles, dates, degrees, numbers, or facts. Only rephrase and reorganize what is provided.
- Rewrite each experience's bullets as achievement-focused, action-verb statements (3–5 per role); quantify only when the input already implies it.
- Write a compelling 2–3 sentence professional summary tailored to the target role.
- Return a deduplicated, ATS-relevant skills list (you may reorder and add closely-related keywords only if clearly supported by the content).
- Return ONLY the JSON object described below — no markdown, no commentary.$analysisBlock

Candidate CV (JSON):
"""
$input
"""

Return a JSON object with EXACTLY these keys:
- "summary": string
- "experiences": array in the SAME order and count as the input; each item = { "bullets": array of strings }
- "skills": array of strings
''';
  }
}

/// The app-wide CV enhancement repository (uses the bound [aiServiceProvider]).
final cvEnhancementRepositoryProvider = Provider<CvEnhancementRepository>(
  (ref) => CvEnhancementRepositoryImpl(ai: ref.watch(aiServiceProvider)),
);
