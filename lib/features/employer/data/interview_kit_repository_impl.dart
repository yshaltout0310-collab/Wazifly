import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/ai/ai_providers.dart';
import '../../../core/services/ai/ai_service.dart';
import '../domain/interview_kit.dart';

/// Generates an employer interview kit for a role via the shared [AiService]
/// seam (one `generateJson` call), parsed defensively. Mirrors
/// `RecruiterInsightsRepositoryImpl` — feature code depends only on the
/// interface; the binding lives in [interviewKitRepositoryProvider].
abstract interface class InterviewKitRepository {
  /// Builds an interview kit for [role] (with an optional free-text [focus]),
  /// with all copy written in [languageCode].
  Future<InterviewKit> generate({
    required String role,
    String focus = '',
    required String languageCode,
  });
}

class InterviewKitRepositoryImpl implements InterviewKitRepository {
  InterviewKitRepositoryImpl({required AiService ai}) : _ai = ai;

  final AiService _ai;

  static const int _questionCount = 6;

  @override
  Future<InterviewKit> generate({
    required String role,
    String focus = '',
    required String languageCode,
  }) async {
    final json = await _ai.generateJson(
      _prompt(role, focus, languageCode),
      systemInstruction: _system(role, languageCode),
    );
    final kit = InterviewKit.fromJson(json).withRole(role);
    if (kit.isEmpty) {
      throw const InterviewKitException(InterviewKitErrorCode.empty);
    }
    return kit;
  }

  String _system(String role, String lang) {
    final language = lang == 'ar' ? 'Arabic' : 'English';
    final target = role.trim().isNotEmpty ? role.trim() : 'the target role';
    return 'You are an expert hiring interviewer helping an employer structure a '
        'fair, effective interview for $target. You write realistic questions, '
        'strong model answers, and honest guidance. Write all text in $language. '
        'Use plain text only — no Markdown (no **bold**, *italics*, # headings, '
        'or backticks).';
  }

  String _prompt(String role, String focus, String lang) {
    final language = lang == 'ar' ? 'Arabic' : 'English';
    final roleLine = role.trim().isNotEmpty ? role.trim() : 'a general role';
    final focusLine = focus.trim().isNotEmpty
        ? 'Emphasize this focus area: ${focus.trim()}.\n'
        : '';
    return '''
Build an interview kit an employer can use to interview candidates for "$roleLine".
$focusLine
Rules:
- Write ALL text values in $language.
- Generate $_questionCount questions, each probing a DISTINCT competency; mix technical/role-specific and behavioral questions appropriate to the role.
- For each question give a concise, strong model answer the interviewer can listen for (2–4 sentences).
- score: an overall 0–100 rating of how well this kit prepares the employer to assess the role (coverage + rigor).
- summary: one or two sentences framing what this interview should establish.
- strengths: 3–5 signals of a strong candidate to look for.
- improvements: 3–5 areas the interviewer should probe carefully or watch out for.
- Return ONLY a JSON object with this exact shape:
{
  "score": 0,
  "summary": "...",
  "questions": [ { "question": "...", "suggestedAnswer": "...", "focus": "short competency" } ],
  "strengths": ["..."],
  "improvements": ["..."]
}
''';
  }
}

/// The app-wide interview-kit repository (uses the bound `aiServiceProvider`).
final interviewKitRepositoryProvider = Provider<InterviewKitRepository>(
  (ref) => InterviewKitRepositoryImpl(ai: ref.watch(aiServiceProvider)),
);
