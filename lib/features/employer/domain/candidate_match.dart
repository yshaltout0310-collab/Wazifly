import 'package:equatable/equatable.dart';

/// Error codes for the employer candidate-matching tool.
enum CandidateMatchErrorCode { empty }

class CandidateMatchException implements Exception {
  const CandidateMatchException(this.code);
  final CandidateMatchErrorCode code;
  @override
  String toString() => 'CandidateMatchException(${code.name})';
}

/// A primitive candidate profile fed to the ranker — decoupled from
/// `Application`/`ApplicantSnapshot` so the repository stays feature-agnostic and
/// unit-testable (mirrors how `RecruiterInsightsContext` flattens analytics).
class CandidateProfile extends Equatable {
  const CandidateProfile({
    required this.id,
    required this.name,
    this.headline = '',
    this.location = '',
    this.experienceLevel = '',
    this.skills = const [],
    this.resumeSummary = '',
    this.atsScore,
  });

  final String id;
  final String name;
  final String headline;
  final String location;
  final String experienceLevel;
  final List<String> skills;
  final String resumeSummary;
  final int? atsScore;

  @override
  List<Object?> get props =>
      [id, name, headline, location, experienceLevel, skills, resumeSummary, atsScore];
}

/// One AI-ranked candidate recommendation for a role.
class CandidateMatch extends Equatable {
  const CandidateMatch({
    required this.name,
    this.headline = '',
    this.matchScore = 0,
    this.matchingSkills = const [],
    this.experienceSummary = '',
    this.recommendation = '',
  });

  final String name;
  final String headline;

  /// Fit score for the target role, 0–100.
  final int matchScore;
  final List<String> matchingSkills;

  /// One or two sentences summarizing the candidate's experience.
  final String experienceSummary;

  /// The AI's hire/interview recommendation for this candidate.
  final String recommendation;

  Map<String, dynamic> toJson() => {
        'name': name,
        'headline': headline,
        'matchScore': matchScore,
        'matchingSkills': matchingSkills,
        'experienceSummary': experienceSummary,
        'recommendation': recommendation,
      };

  factory CandidateMatch.fromJson(Map<String, dynamic> json) => CandidateMatch(
        name: _str(json['name'] ?? json['candidate']),
        headline: _str(json['headline'] ?? json['title']),
        matchScore: _score(json['matchScore'] ?? json['match_score'] ?? json['score']),
        matchingSkills:
            _stringList(json['matchingSkills'] ?? json['matching_skills'] ?? json['skills']),
        experienceSummary: _str(json['experienceSummary'] ??
            json['experience_summary'] ??
            json['experience']),
        recommendation: _str(json['recommendation'] ?? json['reason']),
      );

  @override
  List<Object?> get props =>
      [name, headline, matchScore, matchingSkills, experienceSummary, recommendation];
}

/// The ranked shortlist the AI produced for a role.
class CandidateShortlist extends Equatable {
  const CandidateShortlist({
    this.role = '',
    this.summary = '',
    this.candidates = const [],
  });

  final String role;
  final String summary;
  final List<CandidateMatch> candidates;

  bool get isEmpty => candidates.isEmpty && summary.isEmpty;

  CandidateShortlist withRole(String role) => CandidateShortlist(
        role: role,
        summary: summary,
        candidates: candidates,
      );

  factory CandidateShortlist.fromJson(Map<String, dynamic> json) =>
      CandidateShortlist(
        role: _str(json['role']),
        summary: _str(json['summary'] ?? json['overview']),
        candidates:
            _list(json['candidates'] ?? json['items'], CandidateMatch.fromJson),
      );

  @override
  List<Object?> get props => [role, summary, candidates];
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
