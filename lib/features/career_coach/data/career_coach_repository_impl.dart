import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/ai/ai_message.dart';
import '../../../core/services/ai/ai_providers.dart';
import '../../../core/services/ai/ai_service.dart';
import '../../resume_analyzer/domain/resume_analysis.dart';
import '../domain/career_coach_repository.dart';
import '../domain/chat_message.dart';

/// Streams Career Coach replies via the [AiService]'s multi-turn chat.
///
/// Builds a coach persona system instruction — optionally personalized with the
/// user's analyzed resume — then maps the UI [ChatMessage] history to
/// provider-neutral [AiMessage]s and delegates to `streamChat`. Depends only on
/// the [AiService] abstraction, so the AI provider stays swappable.
class CareerCoachRepositoryImpl implements CareerCoachRepository {
  CareerCoachRepositoryImpl({required AiService ai}) : _ai = ai;

  final AiService _ai;

  @override
  Stream<String> reply({
    required List<ChatMessage> history,
    required String languageCode,
    ResumeAnalysis? resume,
    String? country,
  }) {
    final turns = [
      for (final m in history)
        m.role == ChatRole.assistant
            ? AiMessage.model(m.text)
            : AiMessage.user(m.text),
    ];
    return _ai.streamChat(
      turns,
      systemInstruction: _systemInstruction(languageCode, resume, country),
    );
  }

  String _systemInstruction(
      String languageCode, ResumeAnalysis? resume, String? country) {
    final language = languageCode == 'ar' ? 'Arabic' : 'English';
    final buffer = StringBuffer()
      ..writeln(
          'You are Wazifly\'s AI Career Coach: an encouraging, practical '
          'career mentor. You help with career guidance, learning roadmaps, '
          'skill development, interview preparation, and resume/job advice.')
      ..writeln('Guidelines:')
      ..writeln('- Reply in $language.')
      ..writeln('- Be concise, warm, and actionable; use short paragraphs. Ask '
          'a clarifying question when it helps.')
      ..writeln('- Write plain text only. Do NOT use Markdown formatting: no '
          '**bold**, *italics*, # headings, or backticks. For lists, start '
          'lines with "- ".')
      ..writeln('- Stay on career, job-search, and professional-growth topics; '
          'politely redirect unrelated requests.');

    if (country != null && country.trim().isNotEmpty) {
      final c = country.trim();
      // A firm directive (not a soft "when relevant" hint) so replies actually
      // center on the target market — mirrors the Job Matching prompt's
      // `Based in:` line. Otherwise the model drifts to generic global advice.
      buffer.writeln('- The job market is $c. Base ALL job-market, salary, '
          'employer, and opportunity advice on $c: name $c cities/employers, '
          'quote salaries in the local currency, and reflect $c hiring norms. '
          'Default every example and figure to $c unless the user explicitly '
          'asks about another location.');
    }

    if (resume != null) {
      buffer
        ..writeln()
        ..writeln('The user has analyzed their resume. Tailor advice to this '
            'profile when relevant:');
      if (resume.summary.isNotEmpty) {
        buffer.writeln('- Summary: ${resume.summary}');
      }
      if (resume.strengths.isNotEmpty) {
        buffer.writeln('- Strengths: ${resume.strengths.join(', ')}');
      }
      if (resume.weaknesses.isNotEmpty) {
        buffer.writeln('- Areas to improve: ${resume.weaknesses.join(', ')}');
      }
      if (resume.missingSkills.isNotEmpty) {
        buffer.writeln('- Skills to develop: ${resume.missingSkills.join(', ')}');
      }
    } else {
      buffer
        ..writeln()
        ..writeln('The user has not analyzed a resume yet. If resume-specific '
            'advice would help, suggest they try the Resume Analyzer.');
    }
    return buffer.toString();
  }
}

/// The app-wide career coach repository (uses the bound [aiServiceProvider]).
final careerCoachRepositoryProvider = Provider<CareerCoachRepository>(
  (ref) => CareerCoachRepositoryImpl(ai: ref.watch(aiServiceProvider)),
);
