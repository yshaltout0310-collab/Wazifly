import 'package:careerbridge/core/services/ai/ai_exception.dart';
import 'package:careerbridge/core/services/ai/ai_service.dart';
import 'package:careerbridge/features/job_matching/data/job_matching_repository_impl.dart';
import 'package:careerbridge/features/job_matching/domain/job.dart';
import 'package:careerbridge/features/job_matching/domain/job_matching_exception.dart';
import 'package:careerbridge/features/job_matching/domain/jobs_repository.dart';
import 'package:careerbridge/features/resume_analyzer/domain/resume_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns a fixed job list.
class _FakeJobs implements JobsRepository {
  _FakeJobs(this.jobs);
  final List<Job> jobs;
  @override
  Future<List<Job>> fetchJobs() async => jobs;
}

/// Records the prompt and returns a canned JSON map (or throws).
class _FakeAi implements AiService {
  _FakeAi({this.json, this.error});
  final Map<String, dynamic>? json;
  final Object? error;
  String? lastPrompt;
  String? lastSystem;

  @override
  Future<Map<String, dynamic>> generateJson(String prompt,
      {String? systemInstruction}) async {
    lastPrompt = prompt;
    lastSystem = systemInstruction;
    if (error != null) throw error!;
    return json!;
  }

  @override
  Future<String> generateText(String prompt, {String? systemInstruction}) async =>
      '';

  @override
  Stream<String> streamText(String prompt, {String? systemInstruction}) =>
      const Stream.empty();
}

const _analysis = ResumeAnalysis(
  atsScore: 80,
  summary: 'Flutter engineer with Firebase experience.',
  strengths: ['Flutter', 'Dart'],
  weaknesses: ['No testing'],
  missingSkills: ['Kotlin'],
  grammarIssues: [],
  improvementSuggestions: [],
);

Job _job(String id, String title) => Job(
      id: id,
      title: title,
      company: 'Acme',
      location: 'Doha',
      employmentType: 'Full-time',
      seniority: 'Mid',
      description: 'desc',
      requiredSkills: const ['Flutter'],
      remote: false,
    );

void main() {
  final jobs = [_job('a', 'Flutter Engineer'), _job('b', 'Backend Engineer')];

  test('ranks jobs, maps ids to jobs, and sorts best-first', () async {
    final ai = _FakeAi(json: const {
      'matches': [
        {'id': 'b', 'matchScore': 40, 'reason': 'weak'},
        {'id': 'a', 'matchScore': 90, 'reason': 'strong'},
      ],
    });
    final repo = JobMatchingRepositoryImpl(ai: ai, jobs: _FakeJobs(jobs));

    final result =
        await repo.matchJobs(analysis: _analysis, languageCode: 'en');

    expect(result.map((m) => m.job.id), ['a', 'b']); // sorted desc by score
    expect(result.first.matchScore, 90);
    expect(result.first.job.title, 'Flutter Engineer');
    // Prompt carried the profile + jobs and asked for English.
    expect(ai.lastPrompt, contains('Flutter'));
    expect(ai.lastPrompt, contains('English'));
    expect(ai.lastSystem, isNotNull);
  });

  test('asks the model to respond in Arabic for the ar locale', () async {
    final ai = _FakeAi(json: const {
      'matches': [
        {'id': 'a', 'matchScore': 70, 'reason': 'ok'},
      ],
    });
    final repo = JobMatchingRepositoryImpl(ai: ai, jobs: _FakeJobs(jobs));

    await repo.matchJobs(analysis: _analysis, languageCode: 'ar');
    expect(ai.lastPrompt, contains('Arabic'));
  });

  test('ignores ids the model invented', () async {
    final ai = _FakeAi(json: const {
      'matches': [
        {'id': 'a', 'matchScore': 80, 'reason': 'ok'},
        {'id': 'ghost', 'matchScore': 99, 'reason': 'nope'},
      ],
    });
    final repo = JobMatchingRepositoryImpl(ai: ai, jobs: _FakeJobs(jobs));

    final result =
        await repo.matchJobs(analysis: _analysis, languageCode: 'en');
    expect(result.map((m) => m.job.id), ['a']);
  });

  test('throws noJobs when the source has no jobs', () async {
    final repo = JobMatchingRepositoryImpl(
        ai: _FakeAi(json: const {}), jobs: _FakeJobs(const []));

    expect(
      () => repo.matchJobs(analysis: _analysis, languageCode: 'en'),
      throwsA(isA<JobMatchingException>()
          .having((e) => e.code, 'code', JobMatchErrorCode.noJobs)),
    );
  });

  test('throws invalidResponse when no usable matches parse', () async {
    final repo = JobMatchingRepositoryImpl(
        ai: _FakeAi(json: const {'matches': []}), jobs: _FakeJobs(jobs));

    expect(
      () => repo.matchJobs(analysis: _analysis, languageCode: 'en'),
      throwsA(isA<AiException>()
          .having((e) => e.code, 'code', AiErrorCode.invalidResponse)),
    );
  });

  test('propagates AI errors (e.g. network)', () async {
    final repo = JobMatchingRepositoryImpl(
      ai: _FakeAi(error: const AiException(AiErrorCode.network)),
      jobs: _FakeJobs(jobs),
    );

    expect(
      () => repo.matchJobs(analysis: _analysis, languageCode: 'en'),
      throwsA(isA<AiException>()
          .having((e) => e.code, 'code', AiErrorCode.network)),
    );
  });
}
