import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/ai/ai_providers.dart';
import '../../../core/services/ai/ai_service.dart';
import '../domain/interview_context.dart';
import '../domain/interview_exception.dart';
import '../domain/interview_models.dart';
import '../domain/interview_repository.dart';

/// Builds localized prompts from an [InterviewContext] and delegates to the
/// [AiService]: `generateJson` for questions/evaluation/scores, `streamText`
/// for the narrative debrief. Defensive-parsed throughout.
class InterviewRepositoryImpl implements InterviewRepository {
  InterviewRepositoryImpl({required AiService ai}) : _ai = ai;

  final AiService _ai;

  @override
  Future<List<InterviewQuestion>> generateQuestions({
    required InterviewType type,
    required InterviewContext context,
    required int count,
    required String languageCode,
  }) async {
    final json = await _ai.generateJson(
      _questionsPrompt(type, context, count, languageCode),
      systemInstruction: _system(type, context.role, languageCode),
    );
    final raw = json['questions'] ?? json['items'];
    final list = raw is List ? raw : const [];
    final questions = <InterviewQuestion>[];
    for (var i = 0; i < list.length; i++) {
      if (list[i] is! Map) continue;
      final q = InterviewQuestion.fromJson(
          Map<String, dynamic>.from(list[i] as Map));
      if (q.text.isEmpty) continue;
      questions.add(q.id.isEmpty
          ? InterviewQuestion(id: 'q${i + 1}', text: q.text, focus: q.focus)
          : q);
    }
    if (questions.isEmpty) {
      throw const InterviewException(InterviewErrorCode.noQuestions);
    }
    return questions;
  }

  @override
  Future<AnswerFeedback> evaluateAnswer({
    required InterviewType type,
    required InterviewQuestion question,
    required String answer,
    required InterviewContext context,
    required String languageCode,
  }) async {
    final json = await _ai.generateJson(
      _evaluatePrompt(type, question, answer, context, languageCode),
      systemInstruction: _system(type, context.role, languageCode),
    );
    final fb = AnswerFeedback.fromJson({...json, 'questionId': question.id});
    // Nothing usable came back.
    if (fb.feedback.isEmpty &&
        fb.scores == const InterviewScores() &&
        fb.strengths.isEmpty &&
        fb.improvements.isEmpty) {
      throw const InterviewException(InterviewErrorCode.emptyEvaluation);
    }
    return fb;
  }

  @override
  Future<InterviewSummary> summarize({
    required InterviewSession session,
    required String languageCode,
  }) async {
    final json = await _ai.generateJson(
      _summaryPrompt(session, languageCode),
      systemInstruction: _system(session.type, session.role, languageCode),
    );
    return InterviewSummary.fromJson(json);
  }

  @override
  Stream<String> streamDebrief({
    required InterviewSession session,
    required String languageCode,
  }) {
    return _ai.streamText(
      _debriefPrompt(session, languageCode),
      systemInstruction: _system(session.type, session.role, languageCode),
    );
  }

  // --- Prompt building ---

  String _system(InterviewType type, String role, String languageCode) {
    final language = languageCode == 'ar' ? 'Arabic' : 'English';
    final target = role.isNotEmpty ? role : 'the candidate\'s target role';
    return 'You are an expert interviewer and interview coach conducting a '
        '${_typeName(type)} interview for $target. You ask realistic questions '
        'and give honest, specific, constructive feedback. Write all text in '
        '$language.';
  }

  String _questionsPrompt(
      InterviewType type, InterviewContext ctx, int count, String lang) {
    final language = lang == 'ar' ? 'Arabic' : 'English';
    return '''
Generate $count realistic ${_typeName(type)} interview questions${ctx.role.isNotEmpty ? ' for the role "${ctx.role}"' : ''}.

Interview focus: ${_typeGuidance(type)}
${_contextBlock(ctx)}
Rules:
- Write ALL text in $language.
- Each question probes a DISTINCT area; scale difficulty to the candidate's experience level.
- Keep each question to one or two sentences.
- Return ONLY a JSON object with this exact shape:
{ "questions": [ { "id": "q1", "question": "...", "focus": "short skill or area" } ] }
''';
  }

  String _evaluatePrompt(InterviewType type, InterviewQuestion q, String answer,
      InterviewContext ctx, String lang) {
    final language = lang == 'ar' ? 'Arabic' : 'English';
    return '''
Evaluate the candidate's answer in a ${_typeName(type)} interview${ctx.role.isNotEmpty ? ' for "${ctx.role}"' : ''}.

Question: "${q.text}"${q.focus.isNotEmpty ? ' (focus: ${q.focus})' : ''}
Candidate's answer:
"""
${answer.trim()}
"""

Score honestly on a 0–100 scale. For HR/behavioral interviews, "technicalAccuracy" reflects relevance and structure (e.g. the STAR method).
Write ALL text in $language. Use plain text only — no Markdown (no **bold**, *italics*, # headings, or backticks).
Return ONLY a JSON object with this exact shape:
{
  "scores": { "overall": 0, "communication": 0, "technicalAccuracy": 0, "confidence": 0, "clarity": 0 },
  "feedback": "2-3 sentences of specific, constructive feedback",
  "strengths": ["..."],
  "improvements": ["..."],
  "sampleAnswer": "a concise, strong example answer"
}
''';
  }

  String _summaryPrompt(InterviewSession session, String lang) {
    final language = lang == 'ar' ? 'Arabic' : 'English';
    return '''
Summarize and score this whole ${_typeName(session.type)} practice interview${session.role.isNotEmpty ? ' for "${session.role}"' : ''}.

${_transcript(session)}
Base the scores on the ENTIRE interview (not a naive average of answers). Provide an ordered, actionable improvement plan.
Write ALL text in $language. Use plain text only — no Markdown (no **bold**, *italics*, # headings, or backticks).
Return ONLY a JSON object with this exact shape:
{
  "scores": { "overall": 0, "communication": 0, "technicalAccuracy": 0, "confidence": 0, "clarity": 0 },
  "keyStrengths": ["..."],
  "improvementSuggestions": ["..."],
  "improvementPlan": ["ordered, concrete next steps"]
}
''';
  }

  String _debriefPrompt(InterviewSession session, String lang) {
    final language = lang == 'ar' ? 'Arabic' : 'English';
    return '''
Give a warm, encouraging, and specific overall debrief for this ${_typeName(session.type)} practice interview${session.role.isNotEmpty ? ' for "${session.role}"' : ''}, based on the candidate's answers below.

${_transcript(session)}
Write 2 to 4 short paragraphs in $language. Plain text only — no Markdown, no bold, no headings. Speak directly to the candidate.
''';
  }

  String _transcript(InterviewSession session) {
    final buffer = StringBuffer('Interview transcript:\n');
    for (final q in session.questions) {
      final a = session.answerFor(q.id);
      if (a == null || a.text.trim().isEmpty) continue;
      buffer
        ..writeln('Q: ${q.text}')
        ..writeln('A: ${a.text.trim()}');
      final fb = session.feedbackFor(q.id);
      if (fb != null && fb.scores != const InterviewScores()) {
        buffer.writeln('(answer score: ${fb.scores.overall}/100)');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  String _contextBlock(InterviewContext ctx) {
    if (!ctx.hasPersonalization &&
        ctx.headline.isEmpty &&
        ctx.experienceLevel.isEmpty) {
      return '';
    }
    final b = StringBuffer('Candidate profile (tailor questions to this):\n');
    if (ctx.candidateName.isNotEmpty) b.writeln('- Name: ${ctx.candidateName}');
    if (ctx.headline.isNotEmpty) b.writeln('- Headline: ${ctx.headline}');
    if (ctx.experienceLevel.isNotEmpty) {
      b.writeln('- Experience level: ${ctx.experienceLevel}');
    }
    if (ctx.skills.isNotEmpty) b.writeln('- Skills: ${ctx.skills.join(', ')}');
    if (ctx.resumeSummary.isNotEmpty) {
      b.writeln('- Resume summary: ${ctx.resumeSummary}');
    }
    if (ctx.resumeStrengths.isNotEmpty) {
      b.writeln('- Strengths: ${ctx.resumeStrengths.join(', ')}');
    }
    if (ctx.resumeWeaknesses.isNotEmpty) {
      b.writeln('- Areas to improve: ${ctx.resumeWeaknesses.join(', ')}');
    }
    if (ctx.resumeMissingSkills.isNotEmpty) {
      b.writeln('- Skills to probe/develop: ${ctx.resumeMissingSkills.join(', ')}');
    }
    if (ctx.cvExperiences.isNotEmpty) {
      b.writeln('- Experience: ${ctx.cvExperiences.join('; ')}');
    }
    if (ctx.jobTitle.isNotEmpty) {
      b.writeln('- Target job: ${ctx.jobTitle}');
    }
    if (ctx.jobRequiredSkills.isNotEmpty) {
      b.writeln('- Job requires: ${ctx.jobRequiredSkills.join(', ')}');
    }
    return b.toString();
  }

  String _typeName(InterviewType type) => switch (type) {
        InterviewType.hr => 'HR',
        InterviewType.technical => 'technical',
        InterviewType.behavioral => 'behavioral',
      };

  String _typeGuidance(InterviewType type) => switch (type) {
        InterviewType.hr =>
          'motivation, strengths and weaknesses, career goals, culture fit, and logistics.',
        InterviewType.technical =>
          'role-specific hard skills, problem-solving, and practical scenarios.',
        InterviewType.behavioral =>
          'past situations answered with the STAR method (Situation, Task, Action, Result).',
      };
}

/// The app-wide interview repository (uses the bound [aiServiceProvider]).
final interviewRepositoryProvider = Provider<InterviewRepository>(
  (ref) => InterviewRepositoryImpl(ai: ref.watch(aiServiceProvider)),
);
