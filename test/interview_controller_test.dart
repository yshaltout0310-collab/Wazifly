import 'dart:convert';

import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/ai/ai_exception.dart';
import 'package:careerbridge/core/services/interview_store/in_memory_interview_history_repository.dart';
import 'package:careerbridge/core/services/interview_store/interview_history_repository.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/features/interview_prep/application/interview_controller.dart';
import 'package:careerbridge/features/interview_prep/data/interview_repository_impl.dart';
import 'package:careerbridge/features/interview_prep/domain/interview_context.dart';
import 'package:careerbridge/features/interview_prep/domain/interview_exception.dart';
import 'package:careerbridge/features/interview_prep/domain/interview_models.dart';
import 'package:careerbridge/features/interview_prep/domain/interview_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth.dart';

class FakeInterviewRepository implements InterviewRepository {
  FakeInterviewRepository({this.generateError});
  final Object? generateError;

  @override
  Future<List<InterviewQuestion>> generateQuestions({
    required InterviewType type,
    required InterviewContext context,
    required int count,
    required String languageCode,
  }) async {
    if (generateError != null) throw generateError!;
    return const [
      InterviewQuestion(id: 'q1', text: 'Q1', focus: 'a'),
      InterviewQuestion(id: 'q2', text: 'Q2', focus: 'b'),
    ];
  }

  @override
  Future<AnswerFeedback> evaluateAnswer({
    required InterviewType type,
    required InterviewQuestion question,
    required String answer,
    required InterviewContext context,
    required String languageCode,
  }) async =>
      AnswerFeedback(
        questionId: question.id,
        scores: const InterviewScores(overall: 60),
        feedback: 'ok',
        strengths: const ['clear'],
      );

  @override
  Future<InterviewSummary> summarize({
    required InterviewSession session,
    required String languageCode,
  }) async =>
      const InterviewSummary(
        scores: InterviewScores(overall: 82),
        keyStrengths: ['ownership'],
        improvementPlan: ['practice'],
      );

  @override
  Stream<String> streamDebrief({
    required InterviewSession session,
    required String languageCode,
  }) async* {
    yield 'Great ';
    yield 'job.';
  }
}

Future<ProviderContainer> _container({
  Object? generateError,
  InterviewHistoryRepository? history,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorageService.create();
  final container = ProviderContainer(
    overrides: [
      fakeAuthOverride(),
      localStorageProvider.overrideWithValue(storage),
      interviewRepositoryProvider
          .overrideWithValue(FakeInterviewRepository(generateError: generateError)),
      interviewHistoryRepositoryProvider
          .overrideWithValue(history ?? InMemoryInterviewHistoryRepository()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('start generates questions and enters inProgress', () async {
    final c = await _container();
    final ctrl = c.read(interviewControllerProvider.notifier);
    ctrl.selectType(InterviewType.technical);
    await ctrl.start();

    final state = c.read(interviewControllerProvider);
    expect(state.phase, InterviewPhase.inProgress);
    expect(state.questions.length, 2);
    expect(state.currentIndex, 0);
  });

  test('submitAnswer records feedback for the current question', () async {
    final c = await _container();
    final ctrl = c.read(interviewControllerProvider.notifier);
    await ctrl.start();
    await ctrl.submitAnswer('my answer');

    final state = c.read(interviewControllerProvider);
    expect(state.hasAnsweredCurrent, isTrue);
    expect(state.currentFeedback?.scores.overall, 60);
    expect(state.session?.answeredCount, 1);
  });

  test('finish streams the debrief, scores, and persists the session',
      () async {
    final history = InMemoryInterviewHistoryRepository();
    final c = await _container(history: history);
    final ctrl = c.read(interviewControllerProvider.notifier);
    await ctrl.start();
    await ctrl.submitAnswer('a1');
    ctrl.nextQuestion();
    await ctrl.submitAnswer('a2');
    await ctrl.finish();

    final state = c.read(interviewControllerProvider);
    expect(state.phase, InterviewPhase.summary);
    expect(state.session?.summary?.scores.overall, 82);
    expect(state.session?.summary?.overallFeedback, 'Great job.'); // streamed
    expect(state.session?.summary?.improvementPlan, ['practice']);

    // Persisted to history.
    final saved = await history.findById(state.session!.id);
    expect(saved, isNotNull);
    expect(saved!.isCompleted, isTrue);
  });

  test('a generation failure maps to an error phase', () async {
    final c = await _container(
        generateError: const AiException(AiErrorCode.network));
    final ctrl = c.read(interviewControllerProvider.notifier);
    await ctrl.start();

    final state = c.read(interviewControllerProvider);
    expect(state.phase, InterviewPhase.error);
    expect(state.failure, InterviewFailure.network);
  });

  test('noQuestions failure is surfaced', () async {
    final c = await _container(
        generateError: const InterviewException(InterviewErrorCode.noQuestions));
    final ctrl = c.read(interviewControllerProvider.notifier);
    await ctrl.start();
    expect(c.read(interviewControllerProvider).failure,
        InterviewFailure.noQuestions);
  });

  test('interview context defaults the market to Qatar even with a non-Qatar '
      'persisted profile country', () async {
    // Persist a non-Qatar country; the interview market must still be Qatar.
    SharedPreferences.setMockInitialValues({
      'pref_selected_country': jsonEncode({
        'isoCode': 'EG',
        'name': 'Egypt',
        'dialCode': '+20',
        'flag': '🇪🇬',
      }),
    });
    final storage = await LocalStorageService.create();
    final c = ProviderContainer(overrides: [
      fakeAuthOverride(),
      localStorageProvider.overrideWithValue(storage),
      interviewRepositoryProvider
          .overrideWithValue(FakeInterviewRepository()),
      interviewHistoryRepositoryProvider
          .overrideWithValue(InMemoryInterviewHistoryRepository()),
    ]);
    addTearDown(c.dispose);

    c.read(interviewControllerProvider.notifier).prepare();
    expect(c.read(interviewControllerProvider).context.country, 'Qatar');
  });
}
