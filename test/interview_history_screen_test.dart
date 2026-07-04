import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/services/interview_store/in_memory_interview_history_repository.dart';
import 'package:careerbridge/features/interview_prep/domain/interview_models.dart';
import 'package:careerbridge/features/interview_prep/presentation/interview_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

final _sessions = [
  InterviewSession(
    id: 's1',
    type: InterviewType.technical,
    role: 'Flutter Engineer',
    status: InterviewStatus.completed,
    createdAt: DateTime(2026, 7, 4),
    questions: const [
      InterviewQuestion(id: 'q1', text: 'Q1'),
      InterviewQuestion(id: 'q2', text: 'Q2'),
    ],
    summary: const InterviewSummary(scores: InterviewScores(overall: 82)),
  ),
];

Widget _host(Locale locale) {
  return ProviderScope(
    overrides: [
      interviewHistoryRepositoryProvider.overrideWithValue(
        InMemoryInterviewHistoryRepository(seed: _sessions),
      ),
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
      home: const InterviewHistoryScreen(),
    ),
  );
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();
    testWidgets('interview history renders sessions in $tag', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(locale));
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull, reason: 'threw ($tag)');
      final dir = Directionality.of(
          tester.element(find.byType(InterviewHistoryScreen)));
      expect(dir,
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr);

      // Session tile + overall score render.
      expect(find.textContaining('Flutter Engineer'), findsOneWidget);
      expect(find.text('82'), findsOneWidget);
    });
  }
}
