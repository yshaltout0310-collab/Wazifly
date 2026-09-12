import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../../features/cv_builder/domain/cv_data.dart';
import '../../../features/resume_analyzer/domain/resume_analysis.dart';
import '../../utils/stable_hash.dart';

/// Lifecycle status of a stored CV.
enum CvStatus { active, archived }

/// Parses a status name defensively (unknown/missing → [CvStatus.active]).
CvStatus cvStatusFromName(Object? raw) {
  final name = raw?.toString().trim().toLowerCase();
  for (final s in CvStatus.values) {
    if (s.name == name) return s;
  }
  return CvStatus.active;
}

/// How a CV entered the repository — forward-ready for template/version features.
enum CvSource { built, imported }

CvSource cvSourceFromName(Object? raw) {
  final name = raw?.toString().trim().toLowerCase();
  for (final s in CvSource.values) {
    if (s.name == name) return s;
  }
  return CvSource.built;
}

/// A compact, self-owned per-CV job-match result.
///
/// Deliberately decoupled from `job_matching`'s `JobMatch` (only these primitives
/// are denormalized onto the CV) so the CV repository never depends on that
/// feature. Populated when the user runs Job Matching on a specific CV.
class CvMatchResult extends Equatable {
  const CvMatchResult({
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.score,
    this.reason = '',
  });

  final String jobId;
  final String jobTitle;
  final String company;

  /// Match score, always clamped 0–100.
  final int score;
  final String reason;

  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'jobTitle': jobTitle,
        'company': company,
        'score': score,
        'reason': reason,
      };

  factory CvMatchResult.fromJson(Map<String, dynamic> json) => CvMatchResult(
        jobId: (json['jobId'] ?? '').toString(),
        jobTitle: (json['jobTitle'] ?? '').toString(),
        company: (json['company'] ?? '').toString(),
        score: _clampScore(json['score']),
        reason: (json['reason'] ?? '').toString(),
      );

  @override
  List<Object?> get props => [jobId, jobTitle, company, score, reason];
}

/// A compact, self-owned per-CV recommendations snapshot (headline + a few focus
/// areas). Decoupled from the full `Recommendations` model so the CV repository
/// stays independent of that feature and the document stays lean.
class CvRecommendationSummary extends Equatable {
  const CvRecommendationSummary({
    this.headline = '',
    this.focusAreas = const [],
    required this.generatedAt,
  });

  final String headline;
  final List<String> focusAreas;
  final DateTime generatedAt;

  Map<String, dynamic> toJson() => {
        'headline': headline,
        'focusAreas': focusAreas,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory CvRecommendationSummary.fromJson(Map<String, dynamic> json) =>
      CvRecommendationSummary(
        headline: (json['headline'] ?? '').toString(),
        focusAreas: CvData.stringList(json['focusAreas']),
        generatedAt: _parseDate(json['generatedAt']),
      );

  @override
  List<Object?> get props => [headline, focusAreas, generatedAt];
}

/// One stored CV in the user's repository — the aggregate that unifies metadata,
/// the editable [content] ([CvData]), and this CV's own AI results.
///
/// Reuses the pure [CvData] + [ResumeAnalysis] data classes exactly as the
/// existing core store seams (`cv_draft_store`, `resume_analysis_store`) do — the
/// AI *features* remain unaware of CVs. Lifecycle transitions are pure methods
/// (the `JobPosting` pattern): the controllers compute a new [CvDocument] then
/// persist it via `CvRepository.updateCv`.
class CvDocument extends Equatable {
  const CvDocument({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.analysis,
    this.matchResults = const [],
    this.recommendations,
    this.status = CvStatus.active,
    this.isDefault = false,
    this.version = 1,
    this.source = CvSource.built,
    this.deletedAt,
    this.lastUsedAt,
    this.lastAppliedJobTitle,
    this.lastAppliedCompany,
    this.importHash,
  });

  // --- Identity / metadata ---
  final String id;
  final String ownerUid;
  final String name;

  /// Optional, searchable labels (e.g. "Flutter", "Backend", "Internship").
  /// Filter-ready for a future faceted filter.
  final List<String> tags;

  // --- Content ---
  final CvData content;

  // --- Per-CV AI results (each CV keeps its own) ---
  final ResumeAnalysis? analysis;
  final List<CvMatchResult> matchResults;
  final CvRecommendationSummary? recommendations;

  // --- Lifecycle / state ---
  final CvStatus status;
  final bool isDefault;

  /// Increments on every content edit — the hook for future version history.
  final int version;
  final CvSource source;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Soft-delete marker; non-null means the CV is in the trash (excluded from
  /// the library stream).
  final DateTime? deletedAt;

  // --- Last-used info (auto-updated when applied with this CV) ---
  final DateTime? lastUsedAt;
  final String? lastAppliedJobTitle;
  final String? lastAppliedCompany;

  /// Fingerprint of the **source PDF** for imported CVs (null for built CVs),
  /// used to detect re-importing an identical document (dedup).
  final String? importHash;

  /// ATS score for this CV (from its analysis), or null if not analyzed yet.
  int? get atsScore => analysis?.atsScore;

  bool get isDeleted => deletedAt != null;
  bool get isActive => status == CvStatus.active && !isDeleted;
  bool get isArchived => status == CvStatus.archived && !isDeleted;
  bool get hasAnalysis => analysis != null;

  /// A stable, deterministic fingerprint of the CV **content** (not metadata),
  /// used for import deduplication across sessions. FNV-1a over canonical JSON.
  String get contentHash => stableHash(jsonEncode(content.toJson()));

  /// Deterministic fingerprint of raw source bytes (e.g. an imported PDF), used
  /// to detect re-importing an identical file.
  static String hashBytes(List<int> bytes) =>
      stableHashOfUnits(bytes.map((b) => b & 0xFF).toList(growable: false));

  /// Creates a fresh CV.
  factory CvDocument.create({
    required String id,
    required String ownerUid,
    required String name,
    required CvData content,
    required DateTime now,
    CvSource source = CvSource.built,
    bool isDefault = false,
    List<String> tags = const [],
    ResumeAnalysis? analysis,
    String? importHash,
  }) =>
      CvDocument(
        id: id,
        ownerUid: ownerUid,
        name: name,
        content: content,
        tags: _cleanTags(tags),
        analysis: analysis,
        status: CvStatus.active,
        isDefault: isDefault,
        version: 1,
        source: source,
        createdAt: now,
        updatedAt: now,
        importHash: importHash,
      );

  // --- Pure transitions (compute a new doc; the repo persists it) ---

  CvDocument renamed(String newName, DateTime now) =>
      copyWith(name: newName.trim(), updatedAt: now);

  CvDocument withTags(List<String> newTags, DateTime now) =>
      copyWith(tags: _cleanTags(newTags), updatedAt: now);

  CvDocument archived(DateTime now) =>
      copyWith(status: CvStatus.archived, isDefault: false, updatedAt: now);

  CvDocument restored(DateTime now) =>
      copyWith(status: CvStatus.active, updatedAt: now);

  CvDocument asDefault(DateTime now) => copyWith(isDefault: true, updatedAt: now);

  CvDocument clearedDefault(DateTime now) =>
      copyWith(isDefault: false, updatedAt: now);

  /// Replaces the editable content and **bumps the version** (version-history hook).
  CvDocument withContent(CvData newContent, DateTime now) =>
      copyWith(content: newContent, version: version + 1, updatedAt: now);

  CvDocument withAnalysis(ResumeAnalysis newAnalysis, DateTime now) =>
      copyWith(analysis: newAnalysis, updatedAt: now);

  CvDocument withMatches(List<CvMatchResult> results, DateTime now) =>
      copyWith(matchResults: List.unmodifiable(results), updatedAt: now);

  CvDocument withRecommendations(CvRecommendationSummary rec, DateTime now) =>
      copyWith(recommendations: rec, updatedAt: now);

  /// Records that this CV was used for an application.
  CvDocument markUsed(
    DateTime now, {
    String? jobTitle,
    String? company,
  }) =>
      copyWith(
        lastUsedAt: now,
        lastAppliedJobTitle: jobTitle ?? lastAppliedJobTitle,
        lastAppliedCompany: company ?? lastAppliedCompany,
        updatedAt: now,
      );

  CvDocument softDeleted(DateTime now) =>
      copyWith(deletedAt: now, isDefault: false, updatedAt: now);

  /// A brand-new CV that copies this one's content/tags/AI, resets identity +
  /// default + version. Used by "Duplicate".
  CvDocument duplicatedAs({
    required String id,
    required String name,
    required DateTime now,
  }) =>
      CvDocument(
        id: id,
        ownerUid: ownerUid,
        name: name.trim(),
        content: content,
        tags: tags,
        analysis: analysis,
        matchResults: matchResults,
        recommendations: recommendations,
        status: CvStatus.active,
        isDefault: false,
        version: 1,
        source: source,
        createdAt: now,
        updatedAt: now,
        importHash: importHash,
      );

  CvDocument copyWith({
    String? name,
    CvData? content,
    List<String>? tags,
    ResumeAnalysis? analysis,
    List<CvMatchResult>? matchResults,
    CvRecommendationSummary? recommendations,
    CvStatus? status,
    bool? isDefault,
    int? version,
    CvSource? source,
    DateTime? updatedAt,
    DateTime? deletedAt,
    DateTime? lastUsedAt,
    String? lastAppliedJobTitle,
    String? lastAppliedCompany,
    String? importHash,
  }) =>
      CvDocument(
        id: id,
        ownerUid: ownerUid,
        name: name ?? this.name,
        content: content ?? this.content,
        tags: tags ?? this.tags,
        analysis: analysis ?? this.analysis,
        matchResults: matchResults ?? this.matchResults,
        recommendations: recommendations ?? this.recommendations,
        status: status ?? this.status,
        isDefault: isDefault ?? this.isDefault,
        version: version ?? this.version,
        source: source ?? this.source,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        lastUsedAt: lastUsedAt ?? this.lastUsedAt,
        lastAppliedJobTitle: lastAppliedJobTitle ?? this.lastAppliedJobTitle,
        lastAppliedCompany: lastAppliedCompany ?? this.lastAppliedCompany,
        importHash: importHash ?? this.importHash,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerUid': ownerUid,
        'name': name,
        'tags': tags,
        'content': content.toJson(),
        'contentHash': contentHash,
        if (analysis != null) 'analysis': _analysisToJson(analysis!),
        'matchResults': matchResults.map((m) => m.toJson()).toList(),
        if (recommendations != null) 'recommendations': recommendations!.toJson(),
        'status': status.name,
        'isDefault': isDefault,
        'version': version,
        'source': source.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
        if (lastUsedAt != null) 'lastUsedAt': lastUsedAt!.toIso8601String(),
        if (lastAppliedJobTitle != null)
          'lastAppliedJobTitle': lastAppliedJobTitle,
        if (lastAppliedCompany != null) 'lastAppliedCompany': lastAppliedCompany,
        if (importHash != null) 'importHash': importHash,
      };

  factory CvDocument.fromJson(Map<String, dynamic> json) {
    final created = _parseDate(json['createdAt']);
    return CvDocument(
      id: (json['id'] ?? '').toString(),
      ownerUid: (json['ownerUid'] ?? json['owner_uid'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      tags: CvData.stringList(json['tags']),
      content: json['content'] is Map
          ? CvData.fromJson(Map<String, dynamic>.from(json['content'] as Map))
          : const CvData(),
      analysis: json['analysis'] is Map
          ? ResumeAnalysis.fromJson(
              Map<String, dynamic>.from(json['analysis'] as Map))
          : null,
      matchResults: (json['matchResults'] is List)
          ? (json['matchResults'] as List)
              .whereType<Map>()
              .map((m) => CvMatchResult.fromJson(Map<String, dynamic>.from(m)))
              .toList(growable: false)
          : const [],
      recommendations: json['recommendations'] is Map
          ? CvRecommendationSummary.fromJson(
              Map<String, dynamic>.from(json['recommendations'] as Map))
          : null,
      status: cvStatusFromName(json['status']),
      isDefault: json['isDefault'] == true,
      version: (json['version'] is int) ? json['version'] as int : 1,
      source: cvSourceFromName(json['source']),
      createdAt: created,
      updatedAt:
          json['updatedAt'] == null ? created : _parseDate(json['updatedAt']),
      deletedAt: json['deletedAt'] == null ? null : _parseDate(json['deletedAt']),
      lastUsedAt:
          json['lastUsedAt'] == null ? null : _parseDate(json['lastUsedAt']),
      lastAppliedJobTitle: json['lastAppliedJobTitle']?.toString(),
      lastAppliedCompany: json['lastAppliedCompany']?.toString(),
      importHash: json['importHash']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerUid,
        name,
        tags,
        content,
        analysis,
        matchResults,
        recommendations,
        status,
        isDefault,
        version,
        source,
        createdAt,
        updatedAt,
        deletedAt,
        lastUsedAt,
        lastAppliedJobTitle,
        lastAppliedCompany,
        importHash,
      ];
}

// ResumeAnalysis has no toJson (it's a read model), so serialize it here for
// persistence. fromJson round-trips this shape.
Map<String, dynamic> _analysisToJson(ResumeAnalysis a) => {
      'atsScore': a.atsScore,
      'summary': a.summary,
      'strengths': a.strengths,
      'weaknesses': a.weaknesses,
      'missingSkills': a.missingSkills,
      'grammarIssues': a.grammarIssues
          .map((g) => {'issue': g.issue, 'suggestion': g.suggestion})
          .toList(),
      'improvementSuggestions': a.improvementSuggestions,
    };

List<String> _cleanTags(List<String> tags) {
  final seen = <String>{};
  final out = <String>[];
  for (final t in tags) {
    final v = t.trim();
    if (v.isEmpty) continue;
    if (seen.add(v.toLowerCase())) out.add(v);
  }
  return List.unmodifiable(out);
}

int _clampScore(Object? raw) {
  final n = raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '') ?? 0;
  return n < 0 ? 0 : (n > 100 ? 100 : n);
}

/// Tolerates ISO-8601 strings, epoch millis, and Firestore `Timestamp`
/// (duck-typed so `shared`/`core` needn't import cloud_firestore).
DateTime _parseDate(Object? raw) {
  if (raw is DateTime) return raw;
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  try {
    final d = (raw as dynamic).toDate();
    if (d is DateTime) return d;
  } catch (_) {/* not a Timestamp */}
  final s = raw?.toString();
  if (s == null || s.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
  return DateTime.tryParse(s) ??
      DateTime.fromMillisecondsSinceEpoch(int.tryParse(s) ?? 0);
}
