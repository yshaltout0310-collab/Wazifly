import 'package:equatable/equatable.dart';

/// A **denormalized, self-contained snapshot** of an applicant captured on the
/// seeker side at apply time and stored on the [Application].
///
/// Why a snapshot (not live cross-user reads): Firestore rules keep every user's
/// `users/{uid}` profile, resume analysis, and interview history private to that
/// user, and the resume/interview data is only session-cached today. So an
/// employer can never read an applicant's private docs — everything they need is
/// captured here instead. Mirrors how [Application] already snapshots the job and
/// `JobPosting` snapshots `companyName`.
///
/// Only plain Dart values are stored (Strings/ints/lists) — no feature enums are
/// imported into `shared/` (that would invert the dependency direction). Enum
/// values are denormalized to their canonical strings.
///
/// [snapshotVersion] is a forward-compatibility marker: bump it when the snapshot
/// shape changes so future readers can migrate or degrade without a data
/// migration. Defensive [fromJson] already tolerates missing fields.
class ApplicantSnapshot extends Equatable {
  const ApplicantSnapshot({
    this.snapshotVersion = currentVersion,
    // profile
    this.name = '',
    this.headline,
    this.location,
    this.photoUrl,
    this.skills = const [],
    this.experienceLevel,
    this.portfolioUrl,
    this.githubUrl,
    this.linkedinUrl,
    // resume
    this.atsScore,
    this.resumeSummary,
    this.resumeStrengths = const [],
    this.resumeUrl,
    // AI job match (precomputed at apply time)
    this.matchScore,
    this.matchReason,
    this.matchingSkills = const [],
    this.missingSkills = const [],
    // interview readiness (lightweight; full history stays private to the seeker)
    this.interviewSessions = 0,
    this.interviewBestScore,
    this.interviewLatestType,
  });

  /// The current snapshot schema version. Bump on shape changes.
  static const int currentVersion = 1;

  final int snapshotVersion;

  // --- profile ---
  final String name;
  final String? headline;
  final String? location;
  final String? photoUrl;
  final List<String> skills;

  /// Canonical experience level (e.g. "Senior") — a string, not the profile enum.
  final String? experienceLevel;
  final String? portfolioUrl;
  final String? githubUrl;
  final String? linkedinUrl;

  // --- resume ---
  final int? atsScore;
  final String? resumeSummary;
  final List<String> resumeStrengths;

  /// Firebase Storage URL of the resume PDF; null until Storage is provisioned
  /// (the viewer degrades gracefully).
  final String? resumeUrl;

  // --- AI match ---
  final int? matchScore;
  final String? matchReason;
  final List<String> matchingSkills;
  final List<String> missingSkills;

  // --- interview readiness ---
  final int interviewSessions;
  final int? interviewBestScore;
  final String? interviewLatestType;

  bool get hasResumeAnalysis => atsScore != null || (resumeSummary ?? '').isNotEmpty;
  bool get hasMatch => matchScore != null;
  bool get hasResumeFile => (resumeUrl ?? '').isNotEmpty;
  bool get hasInterviewActivity => interviewSessions > 0;

  ApplicantSnapshot copyWith({
    int? snapshotVersion,
    String? name,
    String? headline,
    String? location,
    String? photoUrl,
    List<String>? skills,
    String? experienceLevel,
    String? portfolioUrl,
    String? githubUrl,
    String? linkedinUrl,
    int? atsScore,
    String? resumeSummary,
    List<String>? resumeStrengths,
    String? resumeUrl,
    int? matchScore,
    String? matchReason,
    List<String>? matchingSkills,
    List<String>? missingSkills,
    int? interviewSessions,
    int? interviewBestScore,
    String? interviewLatestType,
  }) =>
      ApplicantSnapshot(
        snapshotVersion: snapshotVersion ?? this.snapshotVersion,
        name: name ?? this.name,
        headline: headline ?? this.headline,
        location: location ?? this.location,
        photoUrl: photoUrl ?? this.photoUrl,
        skills: skills ?? this.skills,
        experienceLevel: experienceLevel ?? this.experienceLevel,
        portfolioUrl: portfolioUrl ?? this.portfolioUrl,
        githubUrl: githubUrl ?? this.githubUrl,
        linkedinUrl: linkedinUrl ?? this.linkedinUrl,
        atsScore: atsScore ?? this.atsScore,
        resumeSummary: resumeSummary ?? this.resumeSummary,
        resumeStrengths: resumeStrengths ?? this.resumeStrengths,
        resumeUrl: resumeUrl ?? this.resumeUrl,
        matchScore: matchScore ?? this.matchScore,
        matchReason: matchReason ?? this.matchReason,
        matchingSkills: matchingSkills ?? this.matchingSkills,
        missingSkills: missingSkills ?? this.missingSkills,
        interviewSessions: interviewSessions ?? this.interviewSessions,
        interviewBestScore: interviewBestScore ?? this.interviewBestScore,
        interviewLatestType: interviewLatestType ?? this.interviewLatestType,
      );

  Map<String, dynamic> toJson() => {
        'snapshotVersion': snapshotVersion,
        'name': name,
        if (headline != null) 'headline': headline,
        if (location != null) 'location': location,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'skills': skills,
        if (experienceLevel != null) 'experienceLevel': experienceLevel,
        if (portfolioUrl != null) 'portfolioUrl': portfolioUrl,
        if (githubUrl != null) 'githubUrl': githubUrl,
        if (linkedinUrl != null) 'linkedinUrl': linkedinUrl,
        if (atsScore != null) 'atsScore': atsScore,
        if (resumeSummary != null) 'resumeSummary': resumeSummary,
        'resumeStrengths': resumeStrengths,
        if (resumeUrl != null) 'resumeUrl': resumeUrl,
        if (matchScore != null) 'matchScore': matchScore,
        if (matchReason != null) 'matchReason': matchReason,
        'matchingSkills': matchingSkills,
        'missingSkills': missingSkills,
        'interviewSessions': interviewSessions,
        if (interviewBestScore != null) 'interviewBestScore': interviewBestScore,
        if (interviewLatestType != null) 'interviewLatestType': interviewLatestType,
      };

  factory ApplicantSnapshot.fromJson(Map<String, dynamic> json) =>
      ApplicantSnapshot(
        snapshotVersion: _int(json['snapshotVersion'] ?? json['snapshot_version']) ??
            currentVersion,
        name: _str(json['name']) ?? '',
        headline: _str(json['headline']),
        location: _str(json['location']),
        photoUrl: _str(json['photoUrl'] ?? json['photo_url']),
        skills: _stringList(json['skills']),
        experienceLevel: _str(json['experienceLevel'] ?? json['experience_level']),
        portfolioUrl: _str(json['portfolioUrl'] ?? json['portfolio_url']),
        githubUrl: _str(json['githubUrl'] ?? json['github_url']),
        linkedinUrl: _str(json['linkedinUrl'] ?? json['linkedin_url']),
        atsScore: _clampScore(_int(json['atsScore'] ?? json['ats_score'])),
        resumeSummary: _str(json['resumeSummary'] ?? json['resume_summary']),
        resumeStrengths: _stringList(json['resumeStrengths'] ?? json['resume_strengths']),
        resumeUrl: _str(json['resumeUrl'] ?? json['resume_url']),
        matchScore: _clampScore(_int(json['matchScore'] ?? json['match_score'])),
        matchReason: _str(json['matchReason'] ?? json['match_reason']),
        matchingSkills: _stringList(json['matchingSkills'] ?? json['matching_skills']),
        missingSkills: _stringList(json['missingSkills'] ?? json['missing_skills']),
        interviewSessions:
            _int(json['interviewSessions'] ?? json['interview_sessions']) ?? 0,
        interviewBestScore:
            _clampScore(_int(json['interviewBestScore'] ?? json['interview_best_score'])),
        interviewLatestType:
            _str(json['interviewLatestType'] ?? json['interview_latest_type']),
      );

  @override
  List<Object?> get props => [
        snapshotVersion,
        name,
        headline,
        location,
        photoUrl,
        skills,
        experienceLevel,
        portfolioUrl,
        githubUrl,
        linkedinUrl,
        atsScore,
        resumeSummary,
        resumeStrengths,
        resumeUrl,
        matchScore,
        matchReason,
        matchingSkills,
        missingSkills,
        interviewSessions,
        interviewBestScore,
        interviewLatestType,
      ];
}

// --- shared defensive parsers ---

String? _str(Object? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

int? _int(Object? v) {
  if (v == null) return null;
  return v is num ? v.toInt() : int.tryParse(v.toString());
}

int? _clampScore(int? v) => v?.clamp(0, 100);

List<String> _stringList(Object? v) {
  if (v is List) {
    return v
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
  if (v is String && v.trim().isNotEmpty) {
    return v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
  return const [];
}
