import 'package:equatable/equatable.dart';

/// The kind of interview being practised. Extensible — add a value + its prompt
/// framing and l10n label; nothing else changes.
enum InterviewType {
  hr,
  technical,
  behavioral;

  static InterviewType fromName(Object? value) {
    if (value is! String) return InterviewType.hr;
    final v = value.trim().toLowerCase();
    for (final t in InterviewType.values) {
      if (t.name == v) return t;
    }
    return InterviewType.hr;
  }
}

/// Lifecycle of a practice session.
enum InterviewStatus {
  inProgress,
  completed;

  static InterviewStatus fromName(Object? value) {
    if (value is! String) return InterviewStatus.inProgress;
    final v = value.trim().toLowerCase();
    for (final s in InterviewStatus.values) {
      if (s.name.toLowerCase() == v) return s;
    }
    return InterviewStatus.inProgress;
  }
}

/// A scorecard across five interview dimensions, each clamped to 0–100.
///
/// Used both per-answer (immediate feedback) and per-session (the overall
/// debrief). Defensive parsing mirrors `ResumeAnalysis`/`JobMatch`.
class InterviewScores extends Equatable {
  const InterviewScores({
    this.overall = 0,
    this.communication = 0,
    this.technicalAccuracy = 0,
    this.confidence = 0,
    this.clarity = 0,
  });

  final int overall;
  final int communication;
  final int technicalAccuracy;
  final int confidence;
  final int clarity;

  Map<String, dynamic> toJson() => {
        'overall': overall,
        'communication': communication,
        'technicalAccuracy': technicalAccuracy,
        'confidence': confidence,
        'clarity': clarity,
      };

  factory InterviewScores.fromJson(Map<String, dynamic> json) => InterviewScores(
        overall: _score(json['overall']),
        communication: _score(json['communication']),
        technicalAccuracy:
            _score(json['technicalAccuracy'] ?? json['technical_accuracy']),
        confidence: _score(json['confidence']),
        clarity: _score(json['clarity']),
      );

  static int _score(Object? raw) {
    final n = raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '') ?? 0;
    return n.clamp(0, 100);
  }

  @override
  List<Object?> get props =>
      [overall, communication, technicalAccuracy, confidence, clarity];
}

/// A single interview question. [focus] is the skill/topic area it probes.
class InterviewQuestion extends Equatable {
  const InterviewQuestion({required this.id, required this.text, this.focus = ''});

  final String id;
  final String text;
  final String focus;

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'focus': focus};

  factory InterviewQuestion.fromJson(Map<String, dynamic> json) =>
      InterviewQuestion(
        id: _str(json['id']),
        text: _str(json['text'] ?? json['question']),
        focus: _str(json['focus'] ?? json['area'] ?? json['skill']),
      );

  @override
  List<Object?> get props => [id, text, focus];
}

/// The user's answer to a question.
class InterviewAnswer extends Equatable {
  const InterviewAnswer({required this.questionId, required this.text});

  final String questionId;
  final String text;

  Map<String, dynamic> toJson() => {'questionId': questionId, 'text': text};

  factory InterviewAnswer.fromJson(Map<String, dynamic> json) => InterviewAnswer(
        questionId: _str(json['questionId'] ?? json['question_id']),
        text: _str(json['text'] ?? json['answer']),
      );

  @override
  List<Object?> get props => [questionId, text];
}

/// The AI's evaluation of one answer.
class AnswerFeedback extends Equatable {
  const AnswerFeedback({
    required this.questionId,
    this.scores = const InterviewScores(),
    this.feedback = '',
    this.strengths = const [],
    this.improvements = const [],
    this.sampleAnswer = '',
  });

  final String questionId;
  final InterviewScores scores;
  final String feedback;
  final List<String> strengths;
  final List<String> improvements;
  final String sampleAnswer;

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'scores': scores.toJson(),
        'feedback': feedback,
        'strengths': strengths,
        'improvements': improvements,
        'sampleAnswer': sampleAnswer,
      };

  factory AnswerFeedback.fromJson(Map<String, dynamic> json) => AnswerFeedback(
        questionId: _str(json['questionId'] ?? json['question_id']),
        scores: json['scores'] is Map
            ? InterviewScores.fromJson(
                Map<String, dynamic>.from(json['scores'] as Map))
            : const InterviewScores(),
        feedback: _str(json['feedback']),
        strengths: _stringList(json['strengths']),
        improvements: _stringList(json['improvements']),
        sampleAnswer: _str(json['sampleAnswer'] ?? json['sample_answer']),
      );

  @override
  List<Object?> get props =>
      [questionId, scores, feedback, strengths, improvements, sampleAnswer];
}

/// The overall session debrief. Carries everything a future **Interview Report
/// PDF** needs (overall score via [scores], strengths, suggestions, and a
/// concrete [improvementPlan]) so the report is a pure function of the session —
/// addable later with no model refactor.
class InterviewSummary extends Equatable {
  const InterviewSummary({
    this.scores = const InterviewScores(),
    this.overallFeedback = '',
    this.keyStrengths = const [],
    this.improvementSuggestions = const [],
    this.improvementPlan = const [],
  });

  final InterviewScores scores;
  final String overallFeedback;
  final List<String> keyStrengths;
  final List<String> improvementSuggestions;

  /// Ordered, actionable steps the candidate should take next (the "Improvement
  /// Plan" section of the future report).
  final List<String> improvementPlan;

  bool get isEmpty =>
      overallFeedback.isEmpty &&
      keyStrengths.isEmpty &&
      improvementSuggestions.isEmpty &&
      improvementPlan.isEmpty;

  Map<String, dynamic> toJson() => {
        'scores': scores.toJson(),
        'overallFeedback': overallFeedback,
        'keyStrengths': keyStrengths,
        'improvementSuggestions': improvementSuggestions,
        'improvementPlan': improvementPlan,
      };

  factory InterviewSummary.fromJson(Map<String, dynamic> json) =>
      InterviewSummary(
        scores: json['scores'] is Map
            ? InterviewScores.fromJson(
                Map<String, dynamic>.from(json['scores'] as Map))
            : const InterviewScores(),
        overallFeedback:
            _str(json['overallFeedback'] ?? json['overall_feedback']),
        keyStrengths: _stringList(json['keyStrengths'] ?? json['key_strengths']),
        improvementSuggestions: _stringList(
            json['improvementSuggestions'] ?? json['improvement_suggestions']),
        improvementPlan:
            _stringList(json['improvementPlan'] ?? json['improvement_plan']),
      );

  @override
  List<Object?> get props => [
        scores,
        overallFeedback,
        keyStrengths,
        improvementSuggestions,
        improvementPlan,
      ];
}

/// A full practice-interview session — the persisted history record and the
/// single source of truth for a future Interview Report PDF (Overall Score,
/// Type, Date, Strengths, Improvement Suggestions, Improvement Plan are all
/// derivable from here). Denormalizes [role]/[jobTitle] so the record is
/// self-contained. Firestore-ready via defensive [toJson]/[fromJson].
class InterviewSession extends Equatable {
  const InterviewSession({
    required this.id,
    required this.type,
    this.role = '',
    this.jobId,
    this.jobTitle,
    this.status = InterviewStatus.inProgress,
    this.createdAt,
    this.updatedAt,
    this.questions = const [],
    this.answers = const [],
    this.feedback = const [],
    this.summary,
  });

  final String id;
  final InterviewType type;

  /// Target role the interview practises for (denormalized).
  final String role;

  /// Set when the session was started from a specific job (denormalized snapshot).
  final String? jobId;
  final String? jobTitle;

  final InterviewStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<InterviewQuestion> questions;
  final List<InterviewAnswer> answers;
  final List<AnswerFeedback> feedback;
  final InterviewSummary? summary;

  bool get isCompleted => status == InterviewStatus.completed;
  int get answeredCount => answers.where((a) => a.text.trim().isNotEmpty).length;

  /// Overall score for lists/reports (0 until the summary is generated).
  int get overallScore => summary?.scores.overall ?? 0;

  InterviewAnswer? answerFor(String questionId) {
    for (final a in answers) {
      if (a.questionId == questionId) return a;
    }
    return null;
  }

  AnswerFeedback? feedbackFor(String questionId) {
    for (final f in feedback) {
      if (f.questionId == questionId) return f;
    }
    return null;
  }

  factory InterviewSession.create({
    required String id,
    required InterviewType type,
    required List<InterviewQuestion> questions,
    String role = '',
    String? jobId,
    String? jobTitle,
    required DateTime now,
  }) =>
      InterviewSession(
        id: id,
        type: type,
        role: role,
        jobId: jobId,
        jobTitle: jobTitle,
        status: InterviewStatus.inProgress,
        createdAt: now,
        updatedAt: now,
        questions: questions,
      );

  InterviewSession copyWith({
    InterviewStatus? status,
    DateTime? updatedAt,
    List<InterviewAnswer>? answers,
    List<AnswerFeedback>? feedback,
    InterviewSummary? summary,
  }) =>
      InterviewSession(
        id: id,
        type: type,
        role: role,
        jobId: jobId,
        jobTitle: jobTitle,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        questions: questions,
        answers: answers ?? this.answers,
        feedback: feedback ?? this.feedback,
        summary: summary ?? this.summary,
      );

  /// Records/replaces the answer + its feedback for one question.
  InterviewSession withAnswer(
    InterviewAnswer answer,
    AnswerFeedback fb,
    DateTime now,
  ) {
    final nextAnswers = [
      for (final a in answers)
        if (a.questionId != answer.questionId) a,
      answer,
    ];
    final nextFeedback = [
      for (final f in feedback)
        if (f.questionId != fb.questionId) f,
      fb,
    ];
    return copyWith(
        answers: nextAnswers, feedback: nextFeedback, updatedAt: now);
  }

  /// Finalizes the session with its overall debrief.
  InterviewSession completed(InterviewSummary summary, DateTime now) => copyWith(
        status: InterviewStatus.completed,
        summary: summary,
        updatedAt: now,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'role': role,
        'jobId': jobId,
        'jobTitle': jobTitle,
        'status': status.name,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'questions': questions.map((q) => q.toJson()).toList(),
        'answers': answers.map((a) => a.toJson()).toList(),
        'feedback': feedback.map((f) => f.toJson()).toList(),
        'summary': summary?.toJson(),
      };

  factory InterviewSession.fromJson(Map<String, dynamic> json) =>
      InterviewSession(
        id: _str(json['id']),
        type: InterviewType.fromName(json['type']),
        role: _str(json['role']),
        jobId: (json['jobId'] ?? json['job_id'])?.toString(),
        jobTitle: (json['jobTitle'] ?? json['job_title'])?.toString(),
        status: InterviewStatus.fromName(json['status']),
        createdAt: _date(json['createdAt'] ?? json['created_at']),
        updatedAt: _date(json['updatedAt'] ?? json['updated_at']),
        questions: _list(json['questions'], InterviewQuestion.fromJson),
        answers: _list(json['answers'], InterviewAnswer.fromJson),
        feedback: _list(json['feedback'], AnswerFeedback.fromJson),
        summary: json['summary'] is Map
            ? InterviewSummary.fromJson(
                Map<String, dynamic>.from(json['summary'] as Map))
            : null,
      );

  @override
  List<Object?> get props => [
        id,
        type,
        role,
        jobId,
        jobTitle,
        status,
        createdAt,
        updatedAt,
        questions,
        answers,
        feedback,
        summary,
      ];
}

// --- shared parsers ---

String _str(Object? value) => value?.toString().trim() ?? '';

List<String> _stringList(Object? value) {
  if (value is List) {
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
  if (value is String && value.trim().isNotEmpty) {
    return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
  return const [];
}

List<T> _list<T>(Object? value, T Function(Map<String, dynamic>) parse) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((e) => parse(Map<String, dynamic>.from(e)))
      .toList(growable: false);
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  try {
    final result = (value as dynamic).toDate();
    if (result is DateTime) return result;
  } catch (_) {/* not a Timestamp */}
  return null;
}
