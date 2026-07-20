import 'package:equatable/equatable.dart';

/// A single grammar / writing issue found in the resume, with a fix.
class GrammarIssue extends Equatable {
  const GrammarIssue({required this.issue, required this.suggestion});

  final String issue;
  final String suggestion;

  factory GrammarIssue.fromJson(Map<String, dynamic> json) => GrammarIssue(
        issue: (json['issue'] ?? json['text'] ?? '').toString().trim(),
        suggestion:
            (json['suggestion'] ?? json['correction'] ?? '').toString().trim(),
      );

  bool get isEmpty => issue.isEmpty && suggestion.isEmpty;

  @override
  List<Object?> get props => [issue, suggestion];
}

/// Structured result of an AI resume analysis.
///
/// [ResumeAnalysis.fromJson] is deliberately defensive: the model may omit or
/// mistype fields, so every field falls back to a sane empty value rather than
/// throwing. Callers can rely on non-null lists and a clamped [atsScore].
class ResumeAnalysis extends Equatable {
  const ResumeAnalysis({
    required this.atsScore,
    required this.summary,
    required this.strengths,
    required this.weaknesses,
    required this.missingSkills,
    required this.grammarIssues,
    required this.improvementSuggestions,
    this.careerField = '',
  });

  /// The candidate's detected career field / target role (e.g. "Computer
  /// Science — Cybersecurity"). Empty when the model didn't provide one; the
  /// analyzer asks the model to identify this first so the rest of the
  /// feedback stays anchored to the candidate's actual domain.
  final String careerField;

  /// ATS compatibility score, always clamped to 0–100.
  final int atsScore;

  /// One or two sentence overall summary.
  final String summary;

  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> missingSkills;
  final List<GrammarIssue> grammarIssues;
  final List<String> improvementSuggestions;

  factory ResumeAnalysis.fromJson(Map<String, dynamic> json) {
    return ResumeAnalysis(
      careerField:
          (json['careerField'] ?? json['career_field'] ?? '').toString().trim(),
      atsScore: _parseScore(json['atsScore'] ?? json['ats_score']),
      summary: (json['summary'] ?? '').toString().trim(),
      strengths: _parseStringList(json['strengths']),
      weaknesses: _parseStringList(json['weaknesses']),
      missingSkills:
          _parseStringList(json['missingSkills'] ?? json['missing_skills']),
      grammarIssues: _parseGrammarIssues(
          json['grammarIssues'] ?? json['grammar_issues']),
      improvementSuggestions: _parseStringList(
          json['improvementSuggestions'] ?? json['improvement_suggestions']),
    );
  }

  /// True when the analysis carries no actionable content — used to detect an
  /// unusable/empty AI response.
  bool get isEmpty =>
      summary.isEmpty &&
      strengths.isEmpty &&
      weaknesses.isEmpty &&
      missingSkills.isEmpty &&
      grammarIssues.isEmpty &&
      improvementSuggestions.isEmpty;

  static int _parseScore(Object? raw) {
    final n = raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '') ?? 0;
    return n.clamp(0, 100);
  }

  static List<String> _parseStringList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  static List<GrammarIssue> _parseGrammarIssues(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => GrammarIssue.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => !e.isEmpty)
        .toList(growable: false);
  }

  @override
  List<Object?> get props => [
        careerField,
        atsScore,
        summary,
        strengths,
        weaknesses,
        missingSkills,
        grammarIssues,
        improvementSuggestions,
      ];
}
