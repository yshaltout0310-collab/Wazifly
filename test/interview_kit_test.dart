import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/ai/ai_message.dart';
import 'package:careerbridge/core/services/ai/ai_exception.dart';
import 'package:careerbridge/core/services/ai/ai_providers.dart';
import 'package:careerbridge/core/services/ai/ai_service.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/features/employer/application/interview_kit_controller.dart';
import 'package:careerbridge/features/employer/data/interview_kit_repository_impl.dart';
import 'package:careerbridge/features/employer/domain/interview_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records the prompt and returns canned JSON (or throws).
class _FakeAi implements AiService {
  _FakeAi({this.json, this.error});
  final Map<String, dynamic>? json;
  final Object? error;
  String? lastPrompt;

  @override
  Future<Map<String, dynamic>> generateJson(String prompt,
      {String? systemInstruction}) async {
    lastPrompt = prompt;
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

const _fullKit = {
  'score': 82,
  'summary': 'Assess Flutter depth and collaboration.',
  'questions': [
    {
      'question': 'Explain the widget lifecycle.',
      'suggestedAnswer': 'initState → build → dispose…',
      'focus': 'Flutter'
    },
  ],
  'strengths': ['Clear communication'],
  'improvements': ['Probe state management'],
};

Future<ProviderContainer> _container({Map<String, dynamic>? json, Object? error}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorageService.create();
  final c = ProviderContainer(overrides: [
    localStorageProvider.overrideWithValue(storage),
    aiServiceProvider.overrideWithValue(_FakeAi(json: json, error: error)),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('InterviewKitRepositoryImpl', () {
    test('parses the kit and stamps the requested role', () async {
      final ai = _FakeAi(json: _fullKit);
      final kit = await InterviewKitRepositoryImpl(ai: ai)
          .generate(role: 'Flutter Engineer', languageCode: 'en');

      expect(kit.role, 'Flutter Engineer');
      expect(kit.score, 82);
      expect(kit.questions.single.focus, 'Flutter');
      expect(kit.questions.single.suggestedAnswer, isNotEmpty);
      expect(kit.strengths, contains('Clear communication'));
      expect(kit.improvements, contains('Probe state management'));
      expect(ai.lastPrompt, contains('Flutter Engineer'));
    });

    test('throws InterviewKitException when nothing usable comes back', () async {
      expect(
        () => InterviewKitRepositoryImpl(ai: _FakeAi(json: const {}))
            .generate(role: 'X', languageCode: 'en'),
        throwsA(isA<InterviewKitException>()),
      );
    });
  });

  group('InterviewKitController', () {
    test('generate → ready with the parsed kit', () async {
      final c = await _container(json: _fullKit);
      await c.read(interviewKitControllerProvider.notifier).generate('Flutter Engineer');
      final state = c.read(interviewKitControllerProvider);
      expect(state.phase, InterviewKitPhase.ready);
      expect(state.kit?.score, 82);
    });

    test('maps an AI network error to a network failure', () async {
      final c = await _container(error: const AiException(AiErrorCode.network));
      await c.read(interviewKitControllerProvider.notifier).generate('X');
      final state = c.read(interviewKitControllerProvider);
      expect(state.phase, InterviewKitPhase.error);
      expect(state.failure, InterviewKitFailure.network);
    });
  });
}
