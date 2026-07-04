// ignore_for_file: prefer_const_literals_to_create_immutables
import 'package:careerbridge/features/interview_prep/domain/interview_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InterviewScores', () {
    test('clamps values 0–100 and tolerates snake_case', () {
      final s = InterviewScores.fromJson({
        'overall': 150,
        'communication': -5,
        'technical_accuracy': 72,
        'confidence': '80',
        'clarity': 60,
      });
      expect(s.overall, 100);
      expect(s.communication, 0);
      expect(s.technicalAccuracy, 72);
      expect(s.confidence, 80);
      expect(s.clarity, 60);
    });
  });

  group('AnswerFeedback / InterviewSummary parse', () {
    test('AnswerFeedback parses nested scores + lists', () {
      final fb = AnswerFeedback.fromJson({
        'question_id': 'q1',
        'scores': {'overall': 70},
        'feedback': 'Good structure.',
        'strengths': ['clear', ''],
        'improvements': ['add metrics'],
        'sample_answer': 'A strong answer.',
      });
      expect(fb.questionId, 'q1');
      expect(fb.scores.overall, 70);
      expect(fb.strengths, ['clear']); // blank dropped
      expect(fb.improvements, ['add metrics']);
      expect(fb.sampleAnswer, 'A strong answer.');
    });

    test('InterviewSummary keeps the report fields (plan, strengths)', () {
      final s = InterviewSummary.fromJson({
        'scores': {'overall': 82},
        'overallFeedback': 'Strong overall.',
        'keyStrengths': ['communication'],
        'improvement_suggestions': ['quantify results'],
        'improvement_plan': ['1 mock/week', 'study system design'],
      });
      expect(s.scores.overall, 82);
      expect(s.keyStrengths, ['communication']);
      expect(s.improvementSuggestions, ['quantify results']);
      expect(s.improvementPlan, ['1 mock/week', 'study system design']);
    });
  });

  group('InterviewSession', () {
    final t0 = DateTime(2026, 7, 4, 10);
    const questions = [
      InterviewQuestion(id: 'q1', text: 'Tell me about yourself', focus: 'intro'),
      InterviewQuestion(id: 'q2', text: 'A hard bug you fixed?', focus: 'debugging'),
    ];

    test('create → withAnswer → completed drives status + lookups', () {
      var s = InterviewSession.create(
        id: 's1',
        type: InterviewType.technical,
        role: 'Flutter Engineer',
        questions: questions,
        now: t0,
      );
      expect(s.status, InterviewStatus.inProgress);
      expect(s.overallScore, 0);

      s = s.withAnswer(
        const InterviewAnswer(questionId: 'q1', text: 'I am a dev.'),
        const AnswerFeedback(
            questionId: 'q1', scores: InterviewScores(overall: 60)),
        t0,
      );
      expect(s.answeredCount, 1);
      expect(s.answerFor('q1')?.text, 'I am a dev.');
      expect(s.feedbackFor('q1')?.scores.overall, 60);

      s = s.completed(
        const InterviewSummary(
            scores: InterviewScores(overall: 78),
            keyStrengths: ['ownership'],
            improvementPlan: ['practice STAR']),
        t0,
      );
      expect(s.isCompleted, isTrue);
      expect(s.overallScore, 78); // report Overall Score derives from here
    });

    test('round-trips through toJson/fromJson (report-ready)', () {
      final original = InterviewSession.create(
        id: 's1',
        type: InterviewType.behavioral,
        role: 'PM',
        jobId: 'job7',
        jobTitle: 'Product Manager',
        questions: questions,
        now: t0,
      ).withAnswer(
        const InterviewAnswer(questionId: 'q1', text: 'answer'),
        const AnswerFeedback(
            questionId: 'q1', scores: InterviewScores(overall: 55)),
        t0,
      ).completed(
        const InterviewSummary(
          scores: InterviewScores(
              overall: 80, communication: 85, clarity: 75),
          overallFeedback: 'Nice work.',
          keyStrengths: ['clarity'],
          improvementSuggestions: ['be concise'],
          improvementPlan: ['record answers'],
        ),
        t0,
      );

      final restored = InterviewSession.fromJson(original.toJson());
      expect(restored.type, InterviewType.behavioral);
      expect(restored.jobId, 'job7');
      expect(restored.jobTitle, 'Product Manager');
      expect(restored.isCompleted, isTrue);
      expect(restored.overallScore, 80);
      expect(restored.summary?.improvementPlan, ['record answers']);
      expect(restored.answerFor('q1')?.text, 'answer');
    });

    test('bad enum/status/date degrade gracefully', () {
      final s = InterviewSession.fromJson({
        'id': 's1',
        'type': 'wizard',
        'status': 'nope',
        'createdAt': 1735732800000,
      });
      expect(s.type, InterviewType.hr); // default
      expect(s.status, InterviewStatus.inProgress); // default
      expect(s.createdAt, isNotNull); // epoch millis parsed
    });
  });
}
