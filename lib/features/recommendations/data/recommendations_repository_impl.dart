import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/ai/ai_providers.dart';
import '../../../core/services/ai/ai_service.dart';
import '../domain/recommendation_context.dart';
import '../domain/recommendation_models.dart';
import '../domain/recommendations_exception.dart';
import '../domain/recommendations_repository.dart';

/// Builds one localized holistic prompt from a [RecommendationContext] and
/// delegates to [AiService.generateJson], then parses all six sections
/// defensively. Recommended jobs are filtered to the real jobs universe (by id)
/// so the UI can always deep link. Throws [RecommendationsException] only when
/// nothing usable came back at all.
class RecommendationsRepositoryImpl implements RecommendationsRepository {
  RecommendationsRepositoryImpl({required AiService ai}) : _ai = ai;

  final AiService _ai;

  /// Bounded output counts, kept in the prompt for stable results.
  static const int maxJobs = 5;
  static const int maxSkills = 6;
  static const int maxCerts = 4;
  static const int maxCourses = 4;
  static const int maxRoadmap = 4;
  static const int maxActions = 5;

  @override
  Future<Recommendations> generate({
    required RecommendationContext context,
    required String languageCode,
  }) async {
    final json = await _ai.generateJson(
      _prompt(context, languageCode),
      systemInstruction: _system(languageCode),
    );

    var recs = Recommendations.fromJson(json);

    // Keep only jobs that resolve to a real posting (so cards can navigate);
    // drop any the model invented or that the user already applied to.
    final validIds = {for (final j in context.availableJobs) j.id};
    final filteredJobs = [
      for (final j in recs.recommendedJobs)
        if (validIds.contains(j.jobId) && !context.appliedJobIds.contains(j.jobId))
          _fillJob(j, context),
    ];
    recs = Recommendations(
      headline: recs.headline,
      summary: recs.summary,
      recommendedJobs: filteredJobs,
      skillsToLearn: recs.skillsToLearn,
      certifications: recs.certifications,
      courses: recs.courses,
      careerRoadmap: recs.careerRoadmap,
      nextBestActions: recs.nextBestActions,
    );

    if (!recs.hasContent) {
      throw const RecommendationsException(RecErrorCode.emptyRecommendations);
    }
    return recs;
  }

  /// Backfills a recommended job's denormalized title/company from the universe
  /// when the model omitted them.
  JobRecommendation _fillJob(JobRecommendation j, RecommendationContext ctx) {
    if (j.title.isNotEmpty && j.company.isNotEmpty) return j;
    for (final a in ctx.availableJobs) {
      if (a.id == j.jobId) {
        return JobRecommendation(
          jobId: j.jobId,
          title: j.title.isEmpty ? a.title : j.title,
          company: j.company.isEmpty ? a.company : j.company,
          reason: j.reason,
          confidence: j.confidence,
        );
      }
    }
    return j;
  }

  // --- Prompt building ---

  String _system(String lang) {
    final language = lang == 'ar' ? 'Arabic' : 'English';
    return 'You are an expert career advisor and mentor building a personalized '
        '"For You" plan for a job seeker. Give realistic, specific, and '
        'actionable guidance grounded strictly in the candidate data provided. '
        'Every recommendation must include a clear, personalized reason. Write '
        'all text in $language. Use plain text only — no Markdown (no **bold**, '
        '*italics*, # headings, or backticks).';
  }

  String _prompt(RecommendationContext ctx, String lang) {
    final language = lang == 'ar' ? 'Arabic' : 'English';
    return '''
Produce a personalized career recommendations plan for this candidate.

${_contextBlock(ctx)}
${_jobsBlock(ctx)}
Rules:
- Write ALL text values in $language.
- Every item must include a specific "reason" explaining why it fits THIS candidate (reference their skills, gaps, target roles, or activity).
- recommendedJobs: choose up to $maxJobs jobs ONLY from the "Available jobs" list above, by their exact "id". Never invent jobs or ids. Give each a "confidence" 0–100 reflecting fit strength and a personalized "reason".
- skillsToLearn: up to $maxSkills, aligned with the candidate's missing skills, target roles, and the recommended jobs; set "priority" to high, medium, or low.
- certifications: up to $maxCerts real, well-known certifications with their issuing "provider".
- courses: up to $maxCourses real courses with their "provider" (platform); include a "url" only if you are confident it is correct, else leave it empty.
- careerRoadmap: up to $maxRoadmap ordered steps. "horizon" MUST be one of: thisWeek, nextMonth, next3Months, sixToTwelveMonths.
- nextBestActions: up to $maxActions concrete steps. "type" MUST be one of: analyzeResume, buildCv, practiceInterview, browseJobs, reviewApplications, completeProfile, applyToJob, learnSkill. Set "priority" and an "estimatedTime" (e.g. "15 minutes", "2 hours", "1 week"). For applyToJob, put a real job "id" from the list in "targetId".
- Keep every reason to one or two sentences. Return ONLY a JSON object with this exact shape:
{
  "headline": "a short, warm, personalized greeting",
  "summary": "1-2 sentences on where the candidate stands and what to focus on",
  "recommendedJobs": [ { "jobId": "...", "title": "...", "company": "...", "confidence": 0, "reason": "..." } ],
  "skillsToLearn": [ { "skill": "...", "priority": "high", "reason": "..." } ],
  "certifications": [ { "name": "...", "provider": "...", "reason": "..." } ],
  "courses": [ { "title": "...", "provider": "...", "url": "", "skill": "...", "reason": "..." } ],
  "careerRoadmap": [ { "horizon": "thisWeek", "title": "...", "description": "...", "focusSkills": ["..."] } ],
  "nextBestActions": [ { "type": "analyzeResume", "title": "...", "description": "...", "priority": "high", "estimatedTime": "15 minutes", "targetId": "" } ]
}
''';
  }

  String _jobsBlock(RecommendationContext ctx) {
    if (ctx.availableJobs.isEmpty) return '';
    final b = StringBuffer('Available jobs (recommend ONLY from these, by id):\n');
    for (final j in ctx.availableJobs) {
      final applied = ctx.appliedJobIds.contains(j.id) ? ' [already applied]' : '';
      final skills =
          j.requiredSkills.isEmpty ? '' : ' — needs: ${j.requiredSkills.join(', ')}';
      final level = j.seniority.isEmpty ? '' : ' (${j.seniority})';
      final remote = j.remote ? ', remote' : '';
      b.writeln('- id:${j.id} | ${j.title}$level @ ${j.company}$remote$skills$applied');
    }
    return b.toString();
  }

  String _contextBlock(RecommendationContext ctx) {
    final b = StringBuffer('Candidate profile:\n');
    if (ctx.candidateName.isNotEmpty) b.writeln('- Name: ${ctx.candidateName}');
    if (ctx.headline.isNotEmpty) b.writeln('- Headline: ${ctx.headline}');
    if (ctx.location.isNotEmpty) b.writeln('- Location: ${ctx.location}');
    if (ctx.experienceLevel.isNotEmpty) {
      b.writeln('- Experience level: ${ctx.experienceLevel}');
    }
    b.writeln('- Profile completeness: ${ctx.profileCompletion}%'
        '${ctx.hasLinks ? '' : ' (no portfolio/github/linkedin links)'}');
    if (ctx.allSkills.isNotEmpty) b.writeln('- Skills: ${ctx.allSkills.join(', ')}');
    if (ctx.preferredTitles.isNotEmpty) {
      b.writeln('- Target roles: ${ctx.preferredTitles.join(', ')}');
    }

    if (ctx.resumeSummary.isNotEmpty ||
        ctx.resumeStrengths.isNotEmpty ||
        ctx.resumeMissingSkills.isNotEmpty ||
        ctx.atsScore > 0) {
      b.writeln('Resume analysis:');
      if (ctx.atsScore > 0) b.writeln('- ATS score: ${ctx.atsScore}/100');
      if (ctx.resumeSummary.isNotEmpty) {
        b.writeln('- Summary: ${ctx.resumeSummary}');
      }
      if (ctx.resumeStrengths.isNotEmpty) {
        b.writeln('- Strengths: ${ctx.resumeStrengths.join(', ')}');
      }
      if (ctx.resumeWeaknesses.isNotEmpty) {
        b.writeln('- Weaknesses: ${ctx.resumeWeaknesses.join(', ')}');
      }
      if (ctx.resumeMissingSkills.isNotEmpty) {
        b.writeln('- Missing skills to develop: ${ctx.resumeMissingSkills.join(', ')}');
      }
    }

    if (ctx.cvTargetRole.isNotEmpty || ctx.cvExperiences.isNotEmpty) {
      b.writeln('CV:');
      if (ctx.cvTargetRole.isNotEmpty) {
        b.writeln('- Target role: ${ctx.cvTargetRole}');
      }
      if (ctx.cvExperiences.isNotEmpty) {
        b.writeln('- Experience: ${ctx.cvExperiences.join('; ')}');
      }
    }

    if (ctx.appliedCount > 0 || ctx.savedCount > 0 || ctx.interviewsReached > 0) {
      b.writeln('Application activity:');
      b.writeln('- Applied to ${ctx.appliedCount} job(s), '
          '${ctx.savedCount} saved, ${ctx.interviewsReached} reached interview, '
          '${ctx.offers} offer(s).');
      if (ctx.appliedTitles.isNotEmpty) {
        b.writeln('- Applied roles: ${ctx.appliedTitles.join(', ')}');
      }
    }

    if (ctx.interviewCount > 0) {
      b.writeln('Interview practice:');
      b.writeln('- ${ctx.interviewCount} session(s), '
          'average score ${ctx.avgInterviewScore}/100'
          '${ctx.weakestDimension.isNotEmpty ? ', weakest area: ${ctx.weakestDimension}' : ''}.');
      if (ctx.typesPracticed.isNotEmpty) {
        b.writeln('- Types practiced: ${ctx.typesPracticed.join(', ')}');
      }
    }

    if (!ctx.hasSignal) {
      b.writeln('Note: the candidate has shared little so far — keep guidance '
          'encouraging and include actions that help them complete their '
          'profile, analyze a resume, and build a CV.');
    }
    return b.toString();
  }
}

/// The app-wide recommendations repository (uses the bound `aiServiceProvider`).
final recommendationsRepositoryProvider = Provider<RecommendationsRepository>(
  (ref) => RecommendationsRepositoryImpl(ai: ref.watch(aiServiceProvider)),
);
