import 'package:careerbridge/core/services/ai/ai_exception.dart';
import 'package:careerbridge/core/services/ai/ai_message.dart';
import 'package:careerbridge/core/services/ai/ai_service.dart';
import 'package:careerbridge/features/career_coach/data/career_coach_repository_impl.dart';
import 'package:careerbridge/features/career_coach/domain/chat_message.dart';
import 'package:careerbridge/features/resume_analyzer/domain/resume_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records streamChat args and returns a canned token stream (or errors).
class _FakeAi implements AiService {
  _FakeAi({this.chunks = const ['Hello', ' there'], this.error});
  final List<String> chunks;
  final Object? error;
  List<AiMessage>? lastHistory;
  String? lastSystem;

  @override
  Stream<String> streamChat(List<AiMessage> history,
      {String? systemInstruction}) async* {
    lastHistory = history;
    lastSystem = systemInstruction;
    if (error != null) throw error!;
    for (final c in chunks) {
      yield c;
    }
  }

  @override
  Future<String> generateText(String prompt, {String? systemInstruction}) async =>
      '';
  @override
  Future<Map<String, dynamic>> generateJson(String prompt,
          {String? systemInstruction}) async =>
      const {};
  @override
  Stream<String> streamText(String prompt, {String? systemInstruction}) =>
      const Stream.empty();
}

const _resume = ResumeAnalysis(
  atsScore: 80,
  summary: 'Flutter engineer.',
  strengths: ['Flutter', 'Dart'],
  weaknesses: ['No testing'],
  missingSkills: ['Kotlin'],
  grammarIssues: [],
  improvementSuggestions: [],
);

final _history = <ChatMessage>[
  const ChatMessage(id: 'a', role: ChatRole.user, text: 'Hi coach'),
];

void main() {
  test('streams tokens and maps history to AiMessages', () async {
    final ai = _FakeAi(chunks: const ['Foo', 'Bar']);
    final repo = CareerCoachRepositoryImpl(ai: ai);

    final out = await repo
        .reply(history: _history, languageCode: 'en', resume: null)
        .toList();

    expect(out, ['Foo', 'Bar']);
    expect(ai.lastHistory!.single.role, AiRole.user);
    expect(ai.lastHistory!.single.text, 'Hi coach');
    expect(ai.lastSystem, contains('Career Coach'));
    expect(ai.lastSystem, contains('English'));
  });

  test('asks the model to reply in Arabic for the ar locale', () async {
    final ai = _FakeAi();
    final repo = CareerCoachRepositoryImpl(ai: ai);
    await repo.reply(history: _history, languageCode: 'ar', resume: null).toList();
    expect(ai.lastSystem, contains('Arabic'));
  });

  test('personalizes the system instruction when a resume is present', () async {
    final ai = _FakeAi();
    final repo = CareerCoachRepositoryImpl(ai: ai);
    await repo.reply(history: _history, languageCode: 'en', resume: _resume).toList();

    expect(ai.lastSystem, contains('Flutter engineer.')); // summary
    expect(ai.lastSystem, contains('Kotlin')); // missing skill
    expect(ai.lastSystem, isNot(contains('not analyzed')));
  });

  test('notes the missing resume when none is present', () async {
    final ai = _FakeAi();
    final repo = CareerCoachRepositoryImpl(ai: ai);
    await repo.reply(history: _history, languageCode: 'en', resume: null).toList();
    expect(ai.lastSystem, contains('not analyzed'));
  });

  test('maps model turns back to AiRole.model', () async {
    final ai = _FakeAi();
    final repo = CareerCoachRepositoryImpl(ai: ai);
    final history = <ChatMessage>[
      const ChatMessage(id: 'a', role: ChatRole.user, text: 'Hi'),
      const ChatMessage(id: 'b', role: ChatRole.assistant, text: 'Hello!'),
      const ChatMessage(id: 'c', role: ChatRole.user, text: 'Advice?'),
    ];
    await repo.reply(history: history, languageCode: 'en', resume: null).toList();

    expect(ai.lastHistory!.map((m) => m.role).toList(),
        [AiRole.user, AiRole.model, AiRole.user]);
  });

  test('propagates AI errors', () async {
    final repo = CareerCoachRepositoryImpl(
        ai: _FakeAi(error: const AiException(AiErrorCode.network)));

    expect(
      () => repo.reply(history: _history, languageCode: 'en', resume: null).toList(),
      throwsA(isA<AiException>()
          .having((e) => e.code, 'code', AiErrorCode.network)),
    );
  });
}
