import 'package:careerbridge/core/services/ai/ai_message.dart';
import 'package:careerbridge/core/services/ai/ai_service.dart';
import 'package:careerbridge/features/employer/data/recruiter_insights_repository_impl.dart';
import 'package:careerbridge/features/employer/domain/analytics/recruiter_insights.dart';
import 'package:careerbridge/features/employer/domain/analytics/recruiter_insights_context.dart';
import 'package:careerbridge/features/employer/domain/analytics/recruiter_insights_exception.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake AiService that records the prompt/system instruction and returns a
/// canned JSON map (or throws).
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
    return json ?? const {};
  }

  @override
  Future<String> generateText(String prompt, {String? systemInstruction}) async => '';
  @override
  Stream<String> streamText(String prompt, {String? systemInstruction}) =>
      const Stream.empty();
  @override
  Stream<String> streamChat(List<AiMessage> history, {String? systemInstruction}) =>
      const Stream.empty();
}

const _ctx = RecruiterInsightsContext(
  companyName: 'Acme',
  totalJobs: 3,
  activeJobs: 2,
  totalApplicants: 12,
  applied: 12,
  reviewed: 8,
  interview: 4,
  accepted: 2,
  rejected: 3,
  hireRatePercent: 17,
  interviewRatePercent: 33,
  avgMatchScore: 72,
  topJobs: [InsightJob(title: 'Flutter Engineer', applicants: 7, interviews: 3, hires: 1)],
  topSkills: ['Flutter', 'Dart'],
);

void main() {
  test('parses a full insights response', () async {
    final ai = FakeAiService(json: {
      'headline': 'Solid pipeline',
      'summary': 'You convert well but lose people before interview.',
      'strengths': [
        {'title': 'Good hire rate', 'detail': '17% is strong.'},
      ],
      'bottlenecks': [
        {'title': 'Review drop-off', 'detail': 'Only 33% reach interview.'},
      ],
      'suggestedActions': [
        {'title': 'Speed up review', 'detail': 'Cut review time.', 'priority': 'high'},
      ],
    });
    final repo = RecruiterInsightsRepositoryImpl(ai: ai);
    final r = await repo.generate(context: _ctx, languageCode: 'en');

    expect(r.headline, 'Solid pipeline');
    expect(r.strengths.single.title, 'Good hire rate');
    expect(r.bottlenecks.single.detail, contains('33%'));
    expect(r.suggestedActions.single.priority, InsightPriority.high);
  });

  test('prompt embeds the funnel numbers and honors the language', () async {
    final ai = FakeAiService(json: {'summary': 'ok'});
    final repo = RecruiterInsightsRepositoryImpl(ai: ai);
    await repo.generate(context: _ctx, languageCode: 'ar');

    expect(ai.lastPrompt, contains('12 applied'));
    expect(ai.lastPrompt, contains('Flutter Engineer'));
    expect(ai.lastPrompt, contains('Arabic'));
    expect(ai.lastSystem, contains('no Markdown'));
  });

  test('throws emptyInsights when nothing usable comes back', () async {
    final repo = RecruiterInsightsRepositoryImpl(ai: FakeAiService(json: const {}));
    expect(
      () => repo.generate(context: _ctx, languageCode: 'en'),
      throwsA(isA<RecruiterInsightsException>().having(
          (e) => e.code, 'code', RecruiterInsightsErrorCode.emptyInsights)),
    );
  });

  test('propagates AI errors', () async {
    final repo = RecruiterInsightsRepositoryImpl(
        ai: FakeAiService(error: StateError('boom')));
    expect(() => repo.generate(context: _ctx, languageCode: 'en'),
        throwsA(isA<StateError>()));
  });
}
