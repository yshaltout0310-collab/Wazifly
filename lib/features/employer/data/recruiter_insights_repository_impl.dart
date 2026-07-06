import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/ai/ai_providers.dart';
import '../../../core/services/ai/ai_service.dart';
import '../domain/analytics/recruiter_insights.dart';
import '../domain/analytics/recruiter_insights_context.dart';
import '../domain/analytics/recruiter_insights_exception.dart';
import '../domain/analytics/recruiter_insights_repository.dart';

/// Builds one localized prompt from a [RecruiterInsightsContext] and delegates to
/// [AiService.generateJson], then parses the sections defensively. Throws
/// [RecruiterInsightsException] only when nothing usable came back. Mirrors
/// `RecommendationsRepositoryImpl`.
class RecruiterInsightsRepositoryImpl implements RecruiterInsightsRepository {
  RecruiterInsightsRepositoryImpl({required AiService ai}) : _ai = ai;

  final AiService _ai;

  static const int maxStrengths = 4;
  static const int maxBottlenecks = 4;
  static const int maxActions = 5;

  @override
  Future<RecruiterInsights> generate({
    required RecruiterInsightsContext context,
    required String languageCode,
  }) async {
    final json = await _ai.generateJson(
      _prompt(context, languageCode),
      systemInstruction: _system(languageCode),
    );

    final insights = RecruiterInsights.fromJson(json);
    if (!insights.hasContent) {
      throw const RecruiterInsightsException(
          RecruiterInsightsErrorCode.emptyInsights);
    }
    return insights;
  }

  // --- Prompt building ---

  String _system(String lang) {
    final language = lang == 'ar' ? 'Arabic' : 'English';
    return 'You are an expert technical recruiter and hiring analyst advising an '
        'employer on their recruiting funnel. Give sharp, specific, and '
        'actionable insight grounded strictly in the hiring data provided — never '
        'invent numbers. Reference the actual metrics when explaining a point. '
        'Write all text in $language. Use plain text only — no Markdown (no '
        '**bold**, *italics*, # headings, or backticks).';
  }

  String _prompt(RecruiterInsightsContext ctx, String lang) {
    final language = lang == 'ar' ? 'Arabic' : 'English';
    return '''
Analyze this employer's hiring performance and produce recruiter insights.

${_contextBlock(ctx)}
Rules:
- Write ALL text values in $language.
- Ground every point in the data above; reference concrete numbers (counts, rates, days) where relevant. Do not invent data.
- headline: a short, professional one-line summary of the hiring picture.
- summary: 1-2 sentences on the overall state of the pipeline and the single most important thing to focus on.
- strengths: up to $maxStrengths things going well, each with a "title" and a grounded "detail".
- bottlenecks: up to $maxBottlenecks problems or drop-off points in the funnel, each with a "title" and a "detail" naming the metric that reveals it.
- suggestedActions: up to $maxActions concrete next steps to improve hiring outcomes, each with a "title", a "detail", and a "priority" of high, medium, or low.
- Keep every detail to one or two sentences. Return ONLY a JSON object with this exact shape:
{
  "headline": "...",
  "summary": "...",
  "strengths": [ { "title": "...", "detail": "..." } ],
  "bottlenecks": [ { "title": "...", "detail": "..." } ],
  "suggestedActions": [ { "title": "...", "detail": "...", "priority": "high" } ]
}
''';
  }

  String _contextBlock(RecruiterInsightsContext ctx) {
    final b = StringBuffer('Hiring analytics');
    if (ctx.companyName.isNotEmpty) b.write(' for ${ctx.companyName}');
    b.writeln(':');
    b.writeln('- Jobs: ${ctx.totalJobs} total, ${ctx.activeJobs} active (published).');
    b.writeln('- Applicants: ${ctx.totalApplicants} total.');
    b.writeln('- Funnel: ${ctx.applied} applied → ${ctx.reviewed} reviewed → '
        '${ctx.interview} interviewed → ${ctx.accepted} hired '
        '(${ctx.rejected} rejected).');
    b.writeln('- Conversion: ${ctx.interviewRatePercent}% reach interview, '
        '${ctx.hireRatePercent}% are hired.');
    if (ctx.avgMatchScore > 0 || ctx.avgAtsScore > 0) {
      b.writeln('- Applicant quality: average AI match ${ctx.avgMatchScore}/100, '
          'average resume ATS ${ctx.avgAtsScore}/100, '
          '${ctx.strongMatchCount} strong-match and ${ctx.weakMatchCount} weak-match applicants.');
    }
    if (ctx.accepted > 0) {
      b.writeln('- Speed: average ${ctx.avgDaysToHire} days to hire.');
    }
    b.writeln('- Pipeline: ${ctx.openApplicants} applicants still open, '
        'averaging ${ctx.avgDaysInPipeline} days waiting.');
    b.writeln('- Recency: ${ctx.applicationsLast7Days} new applicant(s) in the last 7 days.');
    if (ctx.topJobs.isNotEmpty) {
      b.writeln('Top jobs by applicants:');
      for (final j in ctx.topJobs) {
        b.writeln('- ${j.title}: ${j.applicants} applicant(s), '
            '${j.interviews} interviewed, ${j.hires} hired.');
      }
    }
    if (ctx.topSkills.isNotEmpty) {
      b.writeln('Most common applicant skills: ${ctx.topSkills.join(', ')}.');
    }
    return b.toString();
  }
}

/// The app-wide recruiter-insights repository (uses the bound `aiServiceProvider`).
final recruiterInsightsRepositoryProvider =
    Provider<RecruiterInsightsRepository>(
  (ref) => RecruiterInsightsRepositoryImpl(ai: ref.watch(aiServiceProvider)),
);
