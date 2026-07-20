// Test fixtures are plain JSON-shaped literals; const adds nothing here.
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:careerbridge/features/resume_analyzer/domain/resume_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumeAnalysis.fromJson', () {
    test('parses a complete camelCase payload', () {
      final a = ResumeAnalysis.fromJson({
        'atsScore': 82,
        'summary': 'Strong backend profile.',
        'strengths': ['Clear structure', 'Quantified impact'],
        'weaknesses': ['No summary section'],
        'missingSkills': ['Kubernetes', 'GraphQL'],
        'grammarIssues': [
          {'issue': 'Run-on sentence', 'suggestion': 'Split into two.'},
        ],
        'improvementSuggestions': ['Add metrics'],
      });

      expect(a.atsScore, 82);
      expect(a.summary, 'Strong backend profile.');
      expect(a.strengths, ['Clear structure', 'Quantified impact']);
      expect(a.weaknesses, ['No summary section']);
      expect(a.missingSkills, ['Kubernetes', 'GraphQL']);
      expect(a.grammarIssues.single.issue, 'Run-on sentence');
      expect(a.grammarIssues.single.suggestion, 'Split into two.');
      expect(a.improvementSuggestions, ['Add metrics']);
      expect(a.isEmpty, isFalse);
    });

    test('parses the detected careerField (camelCase and snake_case)', () {
      expect(
        ResumeAnalysis.fromJson({
          'careerField': 'Computer Science — Cybersecurity',
          'summary': 'x',
        }).careerField,
        'Computer Science — Cybersecurity',
      );
      expect(
        ResumeAnalysis.fromJson({'career_field': 'Nursing'}).careerField,
        'Nursing',
      );
    });

    test('careerField defaults to empty and does not by itself make it non-empty',
        () {
      // Backward compatible: an old payload without the key still parses.
      final a = ResumeAnalysis.fromJson({'summary': 'x'});
      expect(a.careerField, '');
      // A response carrying ONLY a field label is still treated as empty.
      final onlyField = ResumeAnalysis.fromJson({'careerField': 'Marketing'});
      expect(onlyField.isEmpty, isTrue);
    });

    test('accepts snake_case keys and grammar text/correction aliases', () {
      final a = ResumeAnalysis.fromJson({
        'ats_score': 55,
        'missing_skills': ['Docker'],
        'grammar_issues': [
          {'text': 'teh', 'correction': 'the'},
        ],
        'improvement_suggestions': ['Shorten it'],
      });

      expect(a.atsScore, 55);
      expect(a.missingSkills, ['Docker']);
      expect(a.grammarIssues.single.issue, 'teh');
      expect(a.grammarIssues.single.suggestion, 'the');
      expect(a.improvementSuggestions, ['Shorten it']);
    });

    test('clamps the score and tolerates a string score', () {
      expect(ResumeAnalysis.fromJson({'atsScore': 140}).atsScore, 100);
      expect(ResumeAnalysis.fromJson({'atsScore': -5}).atsScore, 0);
      expect(ResumeAnalysis.fromJson({'atsScore': '73'}).atsScore, 73);
      expect(ResumeAnalysis.fromJson({'atsScore': 'n/a'}).atsScore, 0);
    });

    test('degrades gracefully on missing / mistyped fields', () {
      final a = ResumeAnalysis.fromJson({
        'strengths': 'not a list',
        'weaknesses': null,
      });
      expect(a.atsScore, 0);
      expect(a.strengths, isEmpty);
      expect(a.weaknesses, isEmpty);
      expect(a.grammarIssues, isEmpty);
      expect(a.isEmpty, isTrue);
    });

    test('drops empty entries in lists and grammar issues', () {
      final a = ResumeAnalysis.fromJson({
        'strengths': ['ok', '', '  '],
        'grammarIssues': [
          {'issue': '', 'suggestion': ''},
          {'issue': 'Real', 'suggestion': 'Fix'},
        ],
      });
      expect(a.strengths, ['ok']);
      expect(a.grammarIssues.length, 1);
    });
  });
}
