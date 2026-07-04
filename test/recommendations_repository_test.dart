import 'package:careerbridge/core/services/ai/ai_exception.dart';
import 'package:careerbridge/core/services/ai/ai_message.dart';
import 'package:careerbridge/core/services/ai/ai_service.dart';
import 'package:careerbridge/features/recommendations/data/recommendations_repository_impl.dart';
import 'package:careerbridge/features/recommendations/domain/recommendation_context.dart';
import 'package:careerbridge/features/recommendations/domain/recommendations_exception.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAiService implements AiService {
  FakeAiService({this.json, this.error});
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
    return json ?? {};
  }

  @override
  Future<String> generateText(String p, {String? systemInstruction}) =>
      throw UnimplementedError();
  @override
  Stream<String> streamText(String p, {String? systemInstruction}) =>
      throw UnimplementedError();
  @override
  Stream<String> streamChat(List<AiMessage> h, {String? systemInstruction}) =>
      throw UnimplementedError();
}

const _ctx = RecommendationContext(
  candidateName: 'Sarah',
  skills: ['Flutter'],
  availableJobs: [
    AvailableJob(id: 'j1', title: 'Flutter Dev', company: 'Acme'),
    AvailableJob(id: 'j2', title: 'iOS Dev', company: 'Globex'),
  ],
  appliedJobIds: {'j2'},
);

void main() {
  test('generate parses sections, filters jobs to the universe + applied', () async {
    final ai = FakeAiService(json: {
      'headline': 'Hi',
      'summary': 'go',
      'recommendedJobs': [
        {'jobId': 'j1', 'confidence': 90, 'reason': 'great fit'}, // valid, title backfilled
        {'jobId': 'j2', 'confidence': 50, 'reason': 'applied'}, // excluded (applied)
        {'jobId': 'jX', 'confidence': 80, 'reason': 'invalid'}, // excluded (unknown id)
      ],
      'skillsToLearn': [
        {'skill': 'GraphQL', 'priority': 'high', 'reason': 'gap'},
      ],
      'nextBestActions': [
        {'type': 'buildCv', 'title': 'Build', 'priority': 'high', 'estimatedTime': '2 hours'},
      ],
    });

    final recs = await RecommendationsRepositoryImpl(ai: ai)
        .generate(context: _ctx, languageCode: 'ar');

    expect(recs.recommendedJobs.length, 1);
    expect(recs.recommendedJobs.single.jobId, 'j1');
    expect(recs.recommendedJobs.single.title, 'Flutter Dev'); // backfilled
    expect(recs.recommendedJobs.single.company, 'Acme');
    expect(recs.skillsToLearn.single.skill, 'GraphQL');
    expect(ai.lastPrompt, contains('Arabic'));
    expect(ai.lastSystem, contains('Arabic'));
  });

  test('throws emptyRecommendations when nothing usable comes back', () async {
    final repo = RecommendationsRepositoryImpl(
        ai: FakeAiService(json: {'headline': 'hi'}));
    expect(
      () => repo.generate(context: _ctx, languageCode: 'en'),
      throwsA(isA<RecommendationsException>().having(
          (e) => e.code, 'code', RecErrorCode.emptyRecommendations)),
    );
  });

  test('propagates AI errors', () async {
    final repo = RecommendationsRepositoryImpl(
        ai: FakeAiService(error: const AiException(AiErrorCode.network)));
    expect(
      () => repo.generate(context: _ctx, languageCode: 'en'),
      throwsA(isA<AiException>()),
    );
  });

  test('system instruction forbids Markdown', () async {
    final ai = FakeAiService(json: {
      'skillsToLearn': [
        {'skill': 'x'}
      ]
    });
    await RecommendationsRepositoryImpl(ai: ai)
        .generate(context: _ctx, languageCode: 'en');
    expect(ai.lastSystem, contains('no Markdown'));
    expect(ai.lastPrompt, contains('Available jobs'));
  });
}
