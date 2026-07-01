import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/features/resume_analyzer/application/resume_analyzer_controller.dart';
import 'package:careerbridge/features/resume_analyzer/domain/resume_analysis.dart';
import 'package:careerbridge/features/resume_analyzer/presentation/resume_analyzer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const _sample = ResumeAnalysis(
  atsScore: 76,
  summary: 'Solid resume with room to sharpen impact.',
  strengths: ['Clear layout', 'Strong keywords'],
  weaknesses: ['No quantified metrics'],
  missingSkills: ['Kubernetes', 'GraphQL'],
  grammarIssues: [
    GrammarIssue(issue: 'Run-on sentence', suggestion: 'Split into two.'),
  ],
  improvementSuggestions: ['Quantify your achievements'],
);

Widget _host(Locale locale) {
  return ProviderScope(
    overrides: [
      resumeAnalyzerControllerProvider.overrideWith(
        (ref) => ResumeAnalyzerController.seeded(
          ref,
          const ResumeAnalyzerState(
            status: ResumeStatus.success,
            analysis: _sample,
            fileName: 'resume.pdf',
          ),
        ),
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
      home: const ResumeAnalyzerScreen(),
    ),
  );
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();
    testWidgets('results render in $tag with no overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(locale));
      await tester.pump(const Duration(milliseconds: 800));

      expect(tester.takeException(), isNull, reason: 'threw during render ($tag)');

      final dir = Directionality.of(
          tester.element(find.byType(ResumeAnalyzerScreen)));
      expect(dir,
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr);

      final l10n = await AppLocalizations.delegate.load(locale);
      expect(find.text(l10n.resumeSectionStrengths), findsOneWidget);
      expect(find.text(l10n.resumeSectionMissingSkills), findsOneWidget);
      expect(find.text('76'), findsOneWidget); // ATS score rendered
    });
  }
}
