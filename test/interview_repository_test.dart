import 'package:careerbridge/core/services/ai/ai_exception.dart';
import 'package:careerbridge/core/services/ai/ai_message.dart';
import 'package:careerbridge/core/services/ai/ai_service.dart';
import 'package:careerbridge/features/interview_prep/data/interview_repository_impl.dart';
import 'package:careerbridge/features/interview_prep/domain/interview_context.dart';
import 'package:careerbridge/features/interview_prep/domain/interview_exception.dart';
import 'package:careerbridge/features/interview_prep/domain/interview_models.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAiService implements AiService {
  FakeAiService({this.json, this.chunks, this.error});
  final Map<String, dynamic>? json;
  final List<String>? chunks;
  final Object? error;
  String? lastPrompt;

  @override
  Future<Map<String, dynamic>> generateJson(String prompt,
      {String? systemInstruction}) async {
    lastPrompt = prompt;
    if (error != null) throw error!;
    return json ?? {};
  }

  @override
  Stream<String> streamText(String prompt, {String? systemInstruction}) async* {
    lastPrompt = prompt;
    for (final c in chunks ?? const <String>[]) {
      yield c;
    }
  }

  @override
  Future<String> generateText(String prompt, {String? systemInstruction}) =>
      throw UnimplementedError();
  @override
  Stream<String> streamChat(List<AiMessage> history,
          {String? systemInstruction}) =>
      throw UnimplementedError();
}

const _ctx = InterviewContext(role: 'Flutter Engineer', skills: ['Flutter']);

void main() {
  test('generateQuestions parses the list and passes the language', () async {
    final ai = FakeAiService(json: {
      'questions': [
        {'id': 'q1', 'question': 'Tell me about yourself', 'focus': 'intro'},
        {'question': 'A hard bug?', 'focus': 'debugging'}, // id missing
      ],
    });
    final repo = InterviewRepositoryImpl(ai: ai);
    final qs = await repo.generateQuestions(
        type: InterviewType.hr, context: _ctx, count: 2, languageCode: 'ar');

    expect(qs.length, 2);
    expect(qs[0].text, 'Tell me about yourself');
    expect(qs[1].id, 'q2'); // auto-assigned
    expect(ai.lastPrompt, contains('Arabic'));
  });

  test('generateQuestions throws noQuestions on an empty list', () async {
    final repo = InterviewRepositoryImpl(ai: FakeAiService(json: {'questions': []}));
    expect(
      () => repo.generateQuestions(
          type: InterviewType.hr, context: _ctx, count: 3, languageCode: 'en'),
      throwsA(isA<InterviewException>().having(
          (e) => e.code, 'code', InterviewErrorCode.noQuestions)),
    );
  });

  test('evaluateAnswer returns clamped scores + feedback', () async {
    final ai = FakeAiService(json: {
      'scores': {'overall': 120, 'communication': 70},
      'feedback': 'Solid answer.',
      'strengths': ['clear'],
      'improvements': ['add detail'],
      'sampleAnswer': 'Example.',
    });
    final fb = await InterviewRepositoryImpl(ai: ai).evaluateAnswer(
      type: InterviewType.technical,
      question: const InterviewQuestion(id: 'q1', text: 'Q?'),
      answer: 'my answer',
      context: _ctx,
      languageCode: 'en',
    );
    expect(fb.questionId, 'q1');
    expect(fb.scores.overall, 100); // clamped
    expect(fb.feedback, 'Solid answer.');
    expect(fb.strengths, ['clear']);
  });

  test('evaluateAnswer throws emptyEvaluation on an empty response', () async {
    final repo = InterviewRepositoryImpl(ai: FakeAiService(json: {}));
    expect(
      () => repo.evaluateAnswer(
        type: InterviewType.hr,
        question: const InterviewQuestion(id: 'q1', text: 'Q?'),
        answer: 'a',
        context: _ctx,
        languageCode: 'en',
      ),
      throwsA(isA<InterviewException>().having(
          (e) => e.code, 'code', InterviewErrorCode.emptyEvaluation)),
    );
  });

  test('summarize parses the scorecard + improvement plan', () async {
    final ai = FakeAiService(json: {
      'scores': {'overall': 78, 'clarity': 80},
      'keyStrengths': ['ownership'],
      'improvementSuggestions': ['quantify'],
      'improvementPlan': ['weekly mock', 'study DS&A'],
    });
    final session = InterviewSession.create(
        id: 's1', type: InterviewType.technical, questions: const [],
        now: DateTime(2026));
    final summary = await InterviewRepositoryImpl(ai: ai)
        .summarize(session: session, languageCode: 'en');
    expect(summary.scores.overall, 78);
    expect(summary.keyStrengths, ['ownership']);
    expect(summary.improvementPlan, ['weekly mock', 'study DS&A']);
  });

  test('streamDebrief streams the chunks', () async {
    final ai = FakeAiService(chunks: ['You ', 'did ', 'well.']);
    final session = InterviewSession.create(
        id: 's1', type: InterviewType.hr, questions: const [],
        now: DateTime(2026));
    final text = (await InterviewRepositoryImpl(ai: ai)
            .streamDebrief(session: session, languageCode: 'en')
            .toList())
        .join();
    expect(text, 'You did well.');
  });

  test('propagates AI errors from generateQuestions', () async {
    final repo = InterviewRepositoryImpl(
        ai: FakeAiService(error: const AiException(AiErrorCode.network)));
    expect(
      () => repo.generateQuestions(
          type: InterviewType.hr, context: _ctx, count: 3, languageCode: 'en'),
      throwsA(isA<AiException>()),
    );
  });
}
