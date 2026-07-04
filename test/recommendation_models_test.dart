// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:careerbridge/features/recommendations/domain/recommendation_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Recommendations.fromJson', () {
    test('parses all sections with snake_case + defensive values', () {
      final recs = Recommendations.fromJson({
        'headline': 'Hi Sarah',
        'summary': 'You are close.',
        'recommended_jobs': [
          {
            'job_id': 'j1',
            'title': 'Flutter Dev',
            'company': 'Acme',
            'confidence': 150, // clamped to 100
            'reason': 'fits',
          },
          {'title': '', 'jobId': ''}, // dropped (empty)
        ],
        'skills_to_learn': [
          {'skill': 'GraphQL', 'priority': 'urgent', 'reason': 'gap'}, // -> high
          {'name': 'CI/CD'}, // no priority -> medium
        ],
        'certifications': [
          {'name': 'AWS SAA', 'issuer': 'Amazon', 'reason': 'cloud'},
        ],
        'courses': [
          {
            'course': 'Flutter Bootcamp',
            'platform': 'Udemy',
            'link': 'https://x',
            'skill': 'Flutter',
            'reason': 'depth',
          },
        ],
        'career_roadmap': [
          {'timeframe': 'this week', 'goal': 'Polish CV', 'detail': 'do it', 'skills': ['x']},
          {'horizon': 'quarter', 'title': 'Ship project'},
        ],
        'next_best_actions': [
          {'type': 'analyze_resume', 'title': 'Analyze', 'reason': 'why', 'priority': 'high', 'time': '15 minutes'},
          {'action': 'somethingweird', 'title': 'X'}, // type -> none
        ],
      });

      expect(recs.headline, 'Hi Sarah');
      expect(recs.recommendedJobs.length, 1);
      expect(recs.recommendedJobs.single.jobId, 'j1');
      expect(recs.recommendedJobs.single.confidence, 100); // clamped

      expect(recs.skillsToLearn.length, 2);
      expect(recs.skillsToLearn[0].priority, RecPriority.high); // urgent alias
      expect(recs.skillsToLearn[1].priority, RecPriority.medium);
      expect(recs.skillsToLearn[1].skill, 'CI/CD');

      expect(recs.certifications.single.provider, 'Amazon');
      expect(recs.courses.single.title, 'Flutter Bootcamp');
      expect(recs.courses.single.url, 'https://x');

      expect(recs.careerRoadmap[0].horizon, RecHorizon.thisWeek);
      expect(recs.careerRoadmap[1].horizon, RecHorizon.next3Months);

      expect(recs.nextBestActions[0].type, NextActionType.analyzeResume);
      expect(recs.nextBestActions[0].estimatedTime, '15 minutes');
      expect(recs.nextBestActions[1].type, NextActionType.none);

      expect(recs.hasContent, isTrue);
    });

    test('empty json yields no content', () {
      final recs = Recommendations.fromJson({});
      expect(recs.hasContent, isFalse);
      expect(recs.recommendedJobs, isEmpty);
      expect(recs.nextBestActions, isEmpty);
    });

    test('round-trips through toJson', () {
      const recs = Recommendations(
        headline: 'H',
        summary: 'S',
        recommendedJobs: [
          JobRecommendation(
              jobId: 'j1', title: 'T', company: 'C', confidence: 80, reason: 'r'),
        ],
        skillsToLearn: [
          SkillRecommendation(skill: 'Dart', priority: RecPriority.high, reason: 'r'),
        ],
        careerRoadmap: [
          RoadmapStep(
              horizon: RecHorizon.sixToTwelveMonths,
              title: 't',
              description: 'd',
              focusSkills: ['a']),
        ],
        nextBestActions: [
          NextAction(
              type: NextActionType.buildCv,
              title: 't',
              description: 'd',
              priority: RecPriority.low,
              estimatedTime: '2 hours'),
        ],
      );
      final back = Recommendations.fromJson(recs.toJson());
      expect(back.recommendedJobs.single.confidence, 80);
      expect(back.skillsToLearn.single.priority, RecPriority.high);
      expect(back.careerRoadmap.single.horizon, RecHorizon.sixToTwelveMonths);
      expect(back.nextBestActions.single.type, NextActionType.buildCv);
      expect(back.nextBestActions.single.estimatedTime, '2 hours');
    });

    test('parses generatedAt from ISO and millis', () {
      expect(
        Recommendations.fromJson(
                {'generatedAt': '2026-07-04T10:00:00.000', 'headline': 'h'})
            .generatedAt,
        DateTime.parse('2026-07-04T10:00:00.000'),
      );
      final millis = DateTime(2026, 7, 4).millisecondsSinceEpoch;
      expect(
        Recommendations.fromJson({'generated_at': millis, 'headline': 'h'})
            .generatedAt,
        DateTime.fromMillisecondsSinceEpoch(millis),
      );
    });
  });

  test('stamp sets generatedAt + signature while preserving content', () {
    const recs = Recommendations(
        headline: 'h', skillsToLearn: [SkillRecommendation(skill: 'x')]);
    final now = DateTime(2026, 7, 4, 12);
    final stamped = recs.stamp(generatedAt: now, sourceSignature: 'sig');
    expect(stamped.generatedAt, now);
    expect(stamped.sourceSignature, 'sig');
    expect(stamped.skillsToLearn.single.skill, 'x');
  });

  test('enum alias parsing is tolerant', () {
    expect(RecHorizon.fromName('6-12 months'), RecHorizon.sixToTwelveMonths);
    expect(RecHorizon.fromName('next month'), RecHorizon.nextMonth);
    expect(RecHorizon.fromName(null), RecHorizon.nextMonth);
    expect(NextActionType.fromName('practice_interview'),
        NextActionType.practiceInterview);
    expect(NextActionType.fromName('applyToJob'), NextActionType.applyToJob);
    expect(NextActionType.fromName('garbage'), NextActionType.none);
    expect(RecPriority.fromName('critical'), RecPriority.high);
    expect(RecPriority.fromName(null), RecPriority.medium);
  });
}
