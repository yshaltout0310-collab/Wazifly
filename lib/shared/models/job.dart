import 'package:equatable/equatable.dart';

import 'internship_details.dart';

/// A job posting — the core jobs-platform model, shared across features
/// (browse/detail in `jobs`, ranking in `job_matching`).
///
/// Sourced today from a bundled seed dataset (see `SeedJobsRepository`), but the
/// shape is deliberately generic so a real jobs API can populate the same model
/// later. [Job.fromJson] is defensive: missing/mistyped fields degrade to sane
/// empties rather than throwing.
class Job extends Equatable {
  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.employmentType,
    required this.seniority,
    required this.description,
    required this.requiredSkills,
    required this.remote,
    this.titleAr,
    this.descriptionAr,
    this.locationAr,
    this.internship,
    this.trainsBeginners = false,
  });

  final String id;
  final String title;
  final String company;
  final String location;

  /// e.g. "Full-time", "Contract".
  final String employmentType;

  /// e.g. "Junior", "Mid", "Senior".
  final String seniority;
  final String description;
  final List<String> requiredSkills;
  final bool remote;

  /// Optional Arabic renderings of the free-text fields (seed/employer content).
  /// When the app runs in Arabic these are shown; when absent the English value
  /// is used as a graceful fallback (see [titleFor]/[descriptionFor]/
  /// [locationFor]). Company names, skills (technical terms) are intentionally
  /// not translated.
  final String? titleAr;
  final String? descriptionAr;
  final String? locationAr;

  /// Picks the Arabic variant when [lang] is `ar` and it is non-empty; otherwise
  /// falls back to the base (English) value.
  static String _pick(String base, String? ar, String lang) =>
      (lang == 'ar' && ar != null && ar.trim().isNotEmpty) ? ar : base;

  String titleFor(String lang) => _pick(title, titleAr, lang);
  String descriptionFor(String lang) => _pick(description, descriptionAr, lang);
  String locationFor(String lang) => _pick(location, locationAr, lang);

  /// Optional internship metadata (present only for internships). Projected
  /// from `JobPosting.internship`; drives the internship browse/detail extras.
  final InternshipDetails? internship;

  /// Employer opt-in signalling the role is beginner-friendly (drives a visible
  /// badge; a forward hook for future beginner-weighted recommendations).
  final bool trainsBeginners;

  /// Whether this job is an internship (by embedded details or the canonical
  /// employmentType string).
  bool get isInternship =>
      internship != null ||
      employmentType.trim().toLowerCase() == 'internship';

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        id: (json['id'] ?? '').toString().trim(),
        title: (json['title'] ?? '').toString().trim(),
        company: (json['company'] ?? '').toString().trim(),
        location: (json['location'] ?? '').toString().trim(),
        employmentType:
            (json['employmentType'] ?? json['employment_type'] ?? '')
                .toString()
                .trim(),
        seniority: (json['seniority'] ?? json['level'] ?? '').toString().trim(),
        description: (json['description'] ?? '').toString().trim(),
        requiredSkills: _parseStringList(
            json['requiredSkills'] ?? json['required_skills'] ?? json['skills']),
        remote: _parseBool(json['remote']),
        titleAr: _parseOptString(json['titleAr'] ?? json['title_ar']),
        descriptionAr:
            _parseOptString(json['descriptionAr'] ?? json['description_ar']),
        locationAr: _parseOptString(json['locationAr'] ?? json['location_ar']),
        internship: json['internship'] is Map
            ? InternshipDetails.fromJson(
                Map<String, dynamic>.from(json['internship'] as Map))
            : null,
        trainsBeginners: _parseBool(
            json['trainsBeginners'] ?? json['trains_beginners']),
      );

  static String? _parseOptString(Object? raw) {
    final s = raw?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static List<String> _parseStringList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  static bool _parseBool(Object? raw) {
    if (raw is bool) return raw;
    final s = raw?.toString().toLowerCase().trim();
    return s == 'true' || s == 'yes' || s == '1';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        company,
        location,
        employmentType,
        seniority,
        description,
        requiredSkills,
        remote,
        titleAr,
        descriptionAr,
        locationAr,
        internship,
        trainsBeginners,
      ];
}
