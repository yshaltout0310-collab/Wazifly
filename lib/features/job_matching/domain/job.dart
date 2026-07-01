import 'package:equatable/equatable.dart';

/// A job posting the user can be matched against.
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
      );

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
      ];
}
