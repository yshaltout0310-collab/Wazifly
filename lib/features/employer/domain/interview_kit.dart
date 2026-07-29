import 'package:equatable/equatable.dart';

/// Error codes for the employer interview-kit generator.
enum InterviewKitErrorCode { empty }

/// Thrown when the model returns nothing usable.
class InterviewKitException implements Exception {
  const InterviewKitException(this.code);
  final InterviewKitErrorCode code;
  @override
  String toString() => 'InterviewKitException(${code.name})';
}

/// One interview question paired with a strong model answer the interviewer can
/// listen for. [focus] is the competency/area the question probes.
class InterviewKitQuestion extends Equatable {
  const InterviewKitQuestion({
    required this.question,
    this.suggestedAnswer = '',
    this.focus = '',
  });

  final String question;
  final String suggestedAnswer;
  final String focus;

  Map<String, dynamic> toJson() => {
        'question': question,
        'suggestedAnswer': suggestedAnswer,
        'focus': focus,
      };

  factory InterviewKitQuestion.fromJson(Map<String, dynamic> json) =>
      InterviewKitQuestion(
        question: _str(json['question'] ?? json['text']),
        suggestedAnswer: _str(json['suggestedAnswer'] ??
            json['suggested_answer'] ??
            json['answer'] ??
            json['sampleAnswer']),
        focus: _str(json['focus'] ?? json['area'] ?? json['skill']),
      );

  @override
  List<Object?> get props => [question, suggestedAnswer, focus];
}

/// A generated interview kit for a role: model questions + answers, an overall
/// interview-readiness [score] (0–100), and what to look for ([strengths]) vs.
/// probe carefully ([improvements]).
///
/// Firestore-/report-ready via defensive [toJson]/[fromJson] (mirrors
/// `ResumeAnalysis` / `InterviewSummary`).
class InterviewKit extends Equatable {
  const InterviewKit({
    this.role = '',
    this.score = 0,
    this.summary = '',
    this.questions = const [],
    this.strengths = const [],
    this.improvements = const [],
  });

  /// The target role the kit was built for (denormalized).
  final String role;

  /// Simple overall interview-readiness score, 0–100.
  final int score;

  /// One or two sentences framing the interview.
  final String summary;

  final List<InterviewKitQuestion> questions;

  /// Signals to look for in a strong candidate.
  final List<String> strengths;

  /// Areas the interviewer should probe / watch out for.
  final List<String> improvements;

  bool get isEmpty =>
      questions.isEmpty &&
      strengths.isEmpty &&
      improvements.isEmpty &&
      summary.isEmpty;

  InterviewKit withRole(String role) => InterviewKit(
        role: role,
        score: score,
        summary: summary,
        questions: questions,
        strengths: strengths,
        improvements: improvements,
      );

  Map<String, dynamic> toJson() => {
        'role': role,
        'score': score,
        'summary': summary,
        'questions': questions.map((q) => q.toJson()).toList(),
        'strengths': strengths,
        'improvements': improvements,
      };

  factory InterviewKit.fromJson(Map<String, dynamic> json) => InterviewKit(
        role: _str(json['role']),
        score: _score(json['score'] ?? json['readinessScore']),
        summary: _str(json['summary'] ?? json['overview']),
        questions: _list(json['questions'] ?? json['items'],
            InterviewKitQuestion.fromJson),
        strengths: _stringList(json['strengths'] ?? json['lookFor']),
        improvements: _stringList(
            json['improvements'] ?? json['probe'] ?? json['areasToProbe']),
      );

  @override
  List<Object?> get props =>
      [role, score, summary, questions, strengths, improvements];
}

// --- shared parsers ---

String _str(Object? value) => value?.toString().trim() ?? '';

int _score(Object? raw) {
  final n = raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '') ?? 0;
  return n.clamp(0, 100);
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
  if (value is String && value.trim().isNotEmpty) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
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
