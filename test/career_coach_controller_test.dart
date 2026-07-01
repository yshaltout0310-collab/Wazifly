import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/ai/ai_exception.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/features/career_coach/application/career_coach_controller.dart';
import 'package:careerbridge/features/career_coach/data/career_coach_repository_impl.dart';
import 'package:careerbridge/features/career_coach/domain/career_coach_repository.dart';
import 'package:careerbridge/features/career_coach/domain/chat_message.dart';
import 'package:careerbridge/features/resume_analyzer/domain/resume_analysis.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Streams canned chunks, or errors before yielding.
class _FakeRepo implements CareerCoachRepository {
  _FakeRepo({this.chunks = const ['Hi', ' there'], this.error});
  final List<String> chunks;
  final Object? error;

  @override
  Stream<String> reply({
    required List<ChatMessage> history,
    required String languageCode,
    ResumeAnalysis? resume,
  }) async* {
    if (error != null) throw error!;
    for (final c in chunks) {
      yield c;
    }
  }
}

Future<ProviderContainer> _container(_FakeRepo repo) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorageService.create();
  return ProviderContainer(overrides: [
    localStorageProvider.overrideWithValue(storage),
    careerCoachRepositoryProvider.overrideWithValue(repo),
  ]);
}

void main() {
  test('accumulates streamed tokens into the assistant message', () async {
    final container = await _container(_FakeRepo(chunks: const ['Hel', 'lo!']));
    addTearDown(container.dispose);
    final controller = container.read(careerCoachControllerProvider.notifier);

    await controller.sendMessage('hello coach');
    await pumpEventQueue();

    final state = container.read(careerCoachControllerProvider);
    expect(state.messages.length, 2);
    expect(state.messages[0].role, ChatRole.user);
    expect(state.messages[0].text, 'hello coach');
    expect(state.messages[1].role, ChatRole.assistant);
    expect(state.messages[1].text, 'Hello!');
    expect(state.messages[1].status, ChatMessageStatus.complete);
    expect(state.isStreaming, isFalse);
  });

  test('marks the reply failed and surfaces the failure on error', () async {
    final container = await _container(
        _FakeRepo(error: const AiException(AiErrorCode.network)));
    addTearDown(container.dispose);
    final controller = container.read(careerCoachControllerProvider.notifier);

    await controller.sendMessage('hello');
    await pumpEventQueue();

    final state = container.read(careerCoachControllerProvider);
    expect(state.messages.last.status, ChatMessageStatus.failed);
    expect(state.failure, CoachFailure.network);
    expect(state.isStreaming, isFalse);
  });

  test('treats an empty reply as a failure', () async {
    final container = await _container(_FakeRepo(chunks: const []));
    addTearDown(container.dispose);
    final controller = container.read(careerCoachControllerProvider.notifier);

    await controller.sendMessage('hello');
    await pumpEventQueue();

    final state = container.read(careerCoachControllerProvider);
    expect(state.messages.last.status, ChatMessageStatus.failed);
    expect(state.failure, CoachFailure.emptyResponse);
  });

  test('ignores blank input', () async {
    final container = await _container(_FakeRepo());
    addTearDown(container.dispose);
    final controller = container.read(careerCoachControllerProvider.notifier);

    await controller.sendMessage('   ');
    await pumpEventQueue();

    expect(container.read(careerCoachControllerProvider).messages, isEmpty);
  });

  test('clearChat empties the conversation', () async {
    final container = await _container(_FakeRepo());
    addTearDown(container.dispose);
    final controller = container.read(careerCoachControllerProvider.notifier);

    await controller.sendMessage('hello');
    await pumpEventQueue();
    expect(container.read(careerCoachControllerProvider).messages, isNotEmpty);

    await controller.clearChat();
    expect(container.read(careerCoachControllerProvider).messages, isEmpty);
  });
}
