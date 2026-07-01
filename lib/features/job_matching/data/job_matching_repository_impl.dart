import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/ai/ai_exception.dart';
import '../../../core/services/ai/ai_providers.dart';
import '../../../core/services/ai/ai_service.dart';
import '../../resume_analyzer/domain/resume_analysis.dart';
import '../domain/job.dart';
import '../domain/job_match.dart';
import '../domain/job_matching_exception.dart';
import '../domain/job_matching_repository.dart';
import '../domain/jobs_repository.dart';
import 'seed_jobs_repository.dart';

/// Orchestrates job matching: fetch the available jobs, ask the [AiService] to
/// rank them against the analyzed resume, and map the result to sorted
/// [JobMatch]es. Depends only on the [AiService] and [JobsRepository]
/// abstractions, so both the AI provider and the jobs source are swappable.
class JobMatchingRepositoryImpl implements JobMatchingRepository {
  JobMatchingRepositoryImpl({
    required AiService ai,
    required JobsRepository jobs,
  })  : _ai = ai,
        _jobs = jobs;

  final AiService _ai;
  final JobsRepository _jobs;

  static const String _systemInstruction =
      'You are an expert technical recruiter and job-matching engine. You '
      'compare a candidate profile against job postings and judge fit '
      'objectively. You always respond with only valid JSON.';

  @override
  Future<List<JobMatch>> matchJobs({
    required ResumeAnalysis analysis,
    required String languageCode,
  }) async {
    final jobs = await _jobs.fetchJobs();
    if (jobs.isEmpty) {
      throw const JobMatchingException(JobMatchErrorCode.noJobs);
    }

    final byId = {for (final j in jobs) j.id: j};
    final json = await _ai.generateJson(
      _buildPrompt(analysis, jobs, languageCode),
      systemInstruction: _systemInstruction,
    );

    final raw = json['matches'] ?? json['results'] ?? json['jobs'];
    final matches = <JobMatch>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is! Map) continue;
        final map = Map<String, dynamic>.from(entry);
        final id = (map['id'] ?? map['jobId'] ?? map['job_id'] ?? '')
            .toString()
            .trim();
        final job = byId[id];
        if (job == null) continue; // ignore ids the model invented
        matches.add(JobMatch.fromRanking(map, job));
      }
    }

    if (matches.isEmpty) {
      throw const AiException(AiErrorCode.invalidResponse);
    }

    matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return matches;
  }

  String _buildPrompt(
    ResumeAnalysis analysis,
    List<Job> jobs,
    String languageCode,
  ) {
    final language = languageCode == 'ar' ? 'Arabic' : 'English';
    final jobsBlock = jobs
        .map((j) => '''
- id: "${j.id}"
  title: ${j.title}
  company: ${j.company}
  location: ${j.location}${j.remote ? ' (remote)' : ''}
  employmentType: ${j.employmentType}
  seniority: ${j.seniority}
  requiredSkills: ${j.requiredSkills.join(', ')}
  description: ${j.description}''')
        .join('\n');

    return '''
You are matching one candidate against a list of job postings.

CANDIDATE PROFILE (derived from their resume):
- Summary: ${analysis.summary}
- Strengths: ${_join(analysis.strengths)}
- Weaknesses: ${_join(analysis.weaknesses)}
- Skills to develop: ${_join(analysis.missingSkills)}

JOBS:
$jobsBlock

Return a JSON object with EXACTLY this shape:
{
  "matches": [
    {
      "id": the job id string exactly as given,
      "matchScore": integer 0-100 (how well the candidate fits this job),
      "reason": one or two sentences explaining the fit,
      "matchingSkills": array of skills the candidate has that this job needs,
      "missingSkills": array of skills this job needs that the candidate lacks
    }
  ]
}

Rules:
- Include EVERY job from the list, each exactly once, using its given id.
- Score honestly and differentiate: strong fits high, weak fits low.
- Write "reason" and all text values in $language. Keep skill names as-is.
- Base everything only on the candidate profile and job details above.
- Return ONLY the JSON object — no markdown, no commentary.''';
  }

  static String _join(List<String> items) =>
      items.isEmpty ? 'none' : items.join(', ');
}

/// The app-wide jobs source. Bundled seed data today; swap the binding to plug
/// in a real jobs API later.
final jobsRepositoryProvider =
    Provider<JobsRepository>((ref) => SeedJobsRepository());

/// The app-wide job matching repository (uses the bound [aiServiceProvider]
/// and [jobsRepositoryProvider]).
final jobMatchingRepositoryProvider = Provider<JobMatchingRepository>(
  (ref) => JobMatchingRepositoryImpl(
    ai: ref.watch(aiServiceProvider),
    jobs: ref.watch(jobsRepositoryProvider),
  ),
);
