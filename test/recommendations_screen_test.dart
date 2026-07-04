import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/features/recommendations/application/recommendations_controller.dart';
import 'package:careerbridge/features/recommendations/domain/recommendation_models.dart';
import 'package:careerbridge/features/recommendations/presentation/recommendations_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'support/fake_auth.dart';

final _recs = Recommendations(
  generatedAt: DateTime(2026, 7, 4, 10),
  headline: 'Welcome back, Sarah',
  summary: 'You have strong momentum — here is where to focus next.',
  recommendedJobs: const [
    JobRecommendation(
        jobId: 'j1',
        title: 'Flutter Engineer',
        company: 'Acme',
        confidence: 92,
        reason: 'Matches your Flutter skills and target role.'),
  ],
  skillsToLearn: const [
    SkillRecommendation(
        skill: 'System design',
        priority: RecPriority.high,
        reason: 'Common gap for senior roles.'),
  ],
  certifications: const [
    CertificationRecommendation(
        name: 'AWS Solutions Architect',
        provider: 'Amazon',
        reason: 'Cloud exposure strengthens your profile.'),
  ],
  courses: const [
    CourseRecommendation(
        title: 'Advanced Flutter',
        provider: 'Udemy',
        skill: 'Flutter',
        reason: 'Deepens the skill you already lead with.'),
  ],
  careerRoadmap: const [
    RoadmapStep(
        horizon: RecHorizon.thisWeek,
        title: 'Polish your CV',
        description: 'Run the AI enhancement pass.',
        focusSkills: ['CV']),
    RoadmapStep(
        horizon: RecHorizon.sixToTwelveMonths,
        title: 'Target a senior role',
        description: 'Build a portfolio project.'),
  ],
  nextBestActions: const [
    NextAction(
        type: NextActionType.practiceInterview,
        title: 'Practice a technical interview',
        description: 'Sharpen your system-design answers.',
        priority: RecPriority.high,
        estimatedTime: '30 minutes'),
  ],
);

Widget _host(Locale locale, RecommendationsState seeded) {
  return ProviderScope(
    overrides: [
      fakeAuthOverride(),
      recommendationsControllerProvider
          .overrideWith((ref) => RecommendationsController.seeded(ref, seeded)),
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
      home: const RecommendationsScreen(),
    ),
  );
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();
    final expectedDir =
        locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    testWidgets('ready renders every section in $tag', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = RecommendationsState(
          phase: RecommendationsPhase.ready, recommendations: _recs);
      await tester.pumpWidget(_host(locale, state));
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull, reason: 'threw ($tag)');

      final l10n = await AppLocalizations.delegate.load(locale);
      expect(find.text(l10n.recJobsTitle), findsOneWidget);
      expect(find.text(l10n.recSkillsTitle), findsOneWidget);
      expect(find.text(l10n.recCertsTitle), findsOneWidget);
      expect(find.text(l10n.recCoursesTitle), findsOneWidget);
      expect(find.text(l10n.recRoadmapTitle), findsOneWidget);
      expect(find.text(l10n.recActionsTitle), findsOneWidget);

      final dir = Directionality.of(
          tester.element(find.byType(RecommendationsScreen)));
      expect(dir, expectedDir);
    });

    testWidgets('loading renders a spinner in $tag', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(
          locale, const RecommendationsState(phase: RecommendationsPhase.loading)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull, reason: 'threw ($tag)');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error renders a retry action in $tag', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(
          locale,
          const RecommendationsState(
              phase: RecommendationsPhase.error,
              failure: RecommendationFailure.network)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull, reason: 'threw ($tag)');
      final l10n = await AppLocalizations.delegate.load(locale);
      expect(find.text(l10n.recRetry), findsOneWidget);
    });
  }
}
