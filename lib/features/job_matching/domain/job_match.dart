import 'package:equatable/equatable.dart';

import '../../../shared/models/job.dart';

/// A [Job] paired with the AI's assessment of how well it fits the user's
/// analyzed resume: a [matchScore] (0–100), a short "why it matches" [reason],
/// and the skills that align / are missing.
///
/// [JobMatch.fromRanking] is defensive — the model may omit or mistype fields —
/// mirroring the parsing philosophy of `ResumeAnalysis.fromJson`.
class JobMatch extends Equatable {
  const JobMatch({
    required this.job,
    required this.matchScore,
    required this.reason,
    required this.matchingSkills,
    required this.missingSkills,
  });

  final Job job;

  /// Match strength, always clamped to 0–100.
  final int matchScore;

  /// One or two sentence explanation of the fit, in the user's language.
  final String reason;

  /// Skills from the resume that align with the job.
  final List<String> matchingSkills;

  /// Skills the job wants that the resume appears to lack.
  final List<String> missingSkills;

  /// Builds a match by merging the model's ranking entry with the resolved
  /// [job] it refers to.
  factory JobMatch.fromRanking(Map<String, dynamic> json, Job job) => JobMatch(
        job: job,
        matchScore: _parseScore(json['matchScore'] ?? json['match_score']),
        reason: (json['reason'] ?? json['why'] ?? '').toString().trim(),
        matchingSkills: _parseStringList(
            json['matchingSkills'] ?? json['matching_skills']),
        missingSkills:
            _parseStringList(json['missingSkills'] ?? json['missing_skills']),
      );

  static int _parseScore(Object? raw) {
    final n =
        raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '') ?? 0;
    return n.clamp(0, 100);
  }

  static List<String> _parseStringList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  @override
  List<Object?> get props =>
      [job, matchScore, reason, matchingSkills, missingSkills];
}
