import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/ai/ai_providers.dart';
import '../../../core/services/ai/ai_service.dart';
import '../domain/candidate_match.dart';

/// Ranks a pool of [CandidateProfile]s against a target role via the shared
/// [AiService] seam (one `generateJson` call), parsed defensively. Grounds the
/// model in the supplied candidates — it must not invent people.
abstract interface class CandidateMatchRepository {
  Future<CandidateShortlist> rank({
    required String role,
    required List<CandidateProfile> candidates,
    int topN = 5,
    required String languageCode,
  });
}

class CandidateMatchRepositoryImpl implements CandidateMatchRepository {
  CandidateMatchRepositoryImpl({required AiService ai}) : _ai = ai;

  final AiService _ai;

  @override
  Future<CandidateShortlist> rank({
    required String role,
    required List<CandidateProfile> candidates,
    int topN = 5,
    required String languageCode,
  }) async {
    final json = await _ai.generateJson(
      _prompt(role, candidates, topN, languageCode),
      systemInstruction: _system(languageCode),
    );
    final shortlist = CandidateShortlist.fromJson(json).withRole(role);
    if (shortlist.candidates.isEmpty) {
      throw const CandidateMatchException(CandidateMatchErrorCode.empty);
    }
    return shortlist;
  }

  String _system(String lang) {
    final language = lang == 'ar' ? 'Arabic' : 'English';
    return 'You are an expert technical recruiter screening real applicants for '
        'an employer. Rank ONLY the candidates provided — never invent people or '
        'facts not supported by their data. Be fair, specific, and concise. Write '
        'all text in $language. Use plain text only — no Markdown.';
  }

  String _prompt(
      String role, List<CandidateProfile> candidates, int topN, String lang) {
    final language = lang == 'ar' ? 'Arabic' : 'English';
    final roleLine = role.trim().isNotEmpty ? role.trim() : 'the open role';
    return '''
Rank the following applicants by their fit for "$roleLine" and recommend the best matches.

${_candidatesBlock(candidates)}
Rules:
- Consider ONLY the candidates listed above; use their exact names. Do not invent candidates or data.
- Return the top ${topN < candidates.length ? topN : candidates.length} candidates, best fit first.
- Write ALL text values in $language.
- For each candidate: matchScore (0–100 fit for this role), matchingSkills (their skills relevant to the role), a one–two sentence experienceSummary, and a one–two sentence recommendation (whether/why to interview them).
- summary: one sentence on the overall strength of this applicant pool for the role.
- Return ONLY a JSON object with this exact shape:
{
  "summary": "...",
  "candidates": [
    { "name": "exact name", "headline": "short title", "matchScore": 0, "matchingSkills": ["..."], "experienceSummary": "...", "recommendation": "..." }
  ]
}
''';
  }

  String _candidatesBlock(List<CandidateProfile> candidates) {
    final b = StringBuffer('Applicants (${candidates.length}):\n');
    for (var i = 0; i < candidates.length; i++) {
      final c = candidates[i];
      b.writeln('${i + 1}. ${c.name}');
      if (c.headline.isNotEmpty) b.writeln('   - Headline: ${c.headline}');
      if (c.experienceLevel.isNotEmpty) {
        b.writeln('   - Experience level: ${c.experienceLevel}');
      }
      if (c.location.isNotEmpty) b.writeln('   - Location: ${c.location}');
      if (c.skills.isNotEmpty) b.writeln('   - Skills: ${c.skills.join(', ')}');
      if (c.atsScore != null) b.writeln('   - Resume ATS score: ${c.atsScore}/100');
      if (c.resumeSummary.isNotEmpty) {
        b.writeln('   - Resume summary: ${c.resumeSummary}');
      }
    }
    return b.toString();
  }
}

/// The app-wide candidate-match repository (uses the bound `aiServiceProvider`).
final candidateMatchRepositoryProvider = Provider<CandidateMatchRepository>(
  (ref) => CandidateMatchRepositoryImpl(ai: ref.watch(aiServiceProvider)),
);
