import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/features/interview_prep/application/interview_controller.dart';
import 'package:careerbridge/features/interview_prep/domain/interview_models.dart';
import 'package:careerbridge/features/interview_prep/presentation/interview_prep_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth.dart';

late LocalStorageService _storage;

const _questions = [
  InterviewQuestion(id: 'q1', text: 'Tell me about a hard problem.', focus: 'problem-solving'),
];
const _feedback = AnswerFeedback(
  questionId: 'q1',
  scores: InterviewScores(
      overall: 78, communication: 80, technicalAccuracy: 72, confidence: 75, clarity: 82),
  feedback: 'Clear and structured, with room for more detail.',
  strengths: ['clear structure'],
  improvements: ['add metrics'],
  sampleAnswer: 'A concise strong answer.',
);
const _summary = InterviewSummary(
  scores: InterviewScores(overall: 78, communication: 80, clarity: 82),
  overallFeedback: 'Solid overall performance.',
  keyStrengths: ['communication'],
  improvementSuggestions: ['quantify impact'],
  improvementPlan: ['do a weekly mock', 'study system design'],
);

InterviewSession _session({bool completed = false}) {
  var s = InterviewSession.create(
    id: 's1',
    type: InterviewType.technical,
    role: 'Flutter Engineer',
    questions: _questions,
    now: DateTime(2026, 7, 4),
  ).withAnswer(
    const InterviewAnswer(questionId: 'q1', text: 'my answer'),
    _feedback,
    DateTime(2026, 7, 4),
  );
  if (completed) s = s.completed(_summary, DateTime(2026, 7, 4));
  return s;
}

Widget _host(Locale locale, InterviewState seeded) {
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(_storage),
      fakeAuthOverride(),
      interviewControllerProvider
          .overrideWith((ref) => InterviewController.seeded(ref, seeded)),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      home: const InterviewPrepScreen(),
    ),
  );
}

void main() {
  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    _storage = await LocalStorageService.create();
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();

    testWidgets('feedback card renders in $tag', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = InterviewState(
        phase: InterviewPhase.inProgress,
        type: InterviewType.technical,
        session: _session(),
      );
      await tester.pumpWidget(_host(locale, state));
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull, reason: 'threw ($tag)');
      final l10n = await AppLocalizations.delegate.load(locale);
      expect(find.text(l10n.interviewFeedbackTitle), findsOneWidget);
      expect(find.text('78'), findsWidgets); // overall gauge
    });

    testWidgets('summary renders scores + plan in $tag', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = InterviewState(
        phase: InterviewPhase.summary,
        type: InterviewType.technical,
        session: _session(completed: true),
        debrief: 'Solid overall performance.',
      );
      await tester.pumpWidget(_host(locale, state));
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull, reason: 'threw ($tag)');
      final l10n = await AppLocalizations.delegate.load(locale);
      expect(find.text(l10n.interviewImprovementPlan), findsOneWidget);
      expect(find.text(l10n.interviewDiscussCoach), findsOneWidget);
    });
  }
}
