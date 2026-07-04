import 'package:equatable/equatable.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_profile.dart';
import '../../resume_analyzer/domain/resume_analysis.dart';

/// One work-experience entry on the CV.
class CvExperience extends Equatable {
  const CvExperience({
    this.role = '',
    this.company = '',
    this.location = '',
    this.startDate = '',
    this.endDate = '',
    this.current = false,
    this.bullets = const [],
  });

  final String role;
  final String company;
  final String location;

  /// Free-form period strings (e.g. "2021", "Jan 2021") — CV dates are rarely
  /// full calendar dates, so we keep them as text and localize the "Present".
  final String startDate;
  final String endDate;
  final bool current;

  /// Achievement/responsibility lines (AI rewrites these into strong bullets).
  final List<String> bullets;

  CvExperience copyWith({
    String? role,
    String? company,
    String? location,
    String? startDate,
    String? endDate,
    bool? current,
    List<String>? bullets,
  }) =>
      CvExperience(
        role: role ?? this.role,
        company: company ?? this.company,
        location: location ?? this.location,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        current: current ?? this.current,
        bullets: bullets ?? this.bullets,
      );

  Map<String, dynamic> toJson() => {
        'role': role,
        'company': company,
        'location': location,
        'startDate': startDate,
        'endDate': endDate,
        'current': current,
        'bullets': bullets,
      };

  factory CvExperience.fromJson(Map<String, dynamic> json) => CvExperience(
        role: _str(json['role']),
        company: _str(json['company']),
        location: _str(json['location']),
        startDate: _str(json['startDate'] ?? json['start_date']),
        endDate: _str(json['endDate'] ?? json['end_date']),
        current: json['current'] == true,
        bullets: CvData.stringList(json['bullets']),
      );

  bool get isBlank =>
      role.isEmpty && company.isEmpty && bullets.isEmpty;

  @override
  List<Object?> get props =>
      [role, company, location, startDate, endDate, current, bullets];
}

/// One education entry on the CV.
class CvEducation extends Equatable {
  const CvEducation({
    this.degree = '',
    this.institution = '',
    this.location = '',
    this.startYear = '',
    this.endYear = '',
    this.details = '',
  });

  final String degree;
  final String institution;
  final String location;
  final String startYear;
  final String endYear;
  final String details;

  CvEducation copyWith({
    String? degree,
    String? institution,
    String? location,
    String? startYear,
    String? endYear,
    String? details,
  }) =>
      CvEducation(
        degree: degree ?? this.degree,
        institution: institution ?? this.institution,
        location: location ?? this.location,
        startYear: startYear ?? this.startYear,
        endYear: endYear ?? this.endYear,
        details: details ?? this.details,
      );

  Map<String, dynamic> toJson() => {
        'degree': degree,
        'institution': institution,
        'location': location,
        'startYear': startYear,
        'endYear': endYear,
        'details': details,
      };

  factory CvEducation.fromJson(Map<String, dynamic> json) => CvEducation(
        degree: _str(json['degree']),
        institution: _str(json['institution']),
        location: _str(json['location']),
        startYear: _str(json['startYear'] ?? json['start_year']),
        endYear: _str(json['endYear'] ?? json['end_year']),
        details: _str(json['details']),
      );

  bool get isBlank => degree.isEmpty && institution.isEmpty;

  @override
  List<Object?> get props =>
      [degree, institution, location, startYear, endYear, details];
}

/// One project entry on the CV (optional section).
class CvProject extends Equatable {
  const CvProject({this.name = '', this.description = '', this.link = ''});

  final String name;
  final String description;
  final String link;

  CvProject copyWith({String? name, String? description, String? link}) =>
      CvProject(
        name: name ?? this.name,
        description: description ?? this.description,
        link: link ?? this.link,
      );

  Map<String, dynamic> toJson() =>
      {'name': name, 'description': description, 'link': link};

  factory CvProject.fromJson(Map<String, dynamic> json) => CvProject(
        name: _str(json['name']),
        description: _str(json['description']),
        link: _str(json['link']),
      );

  bool get isBlank => name.isEmpty && description.isEmpty;

  @override
  List<Object?> get props => [name, description, link];
}

/// The full, editable CV document.
///
/// Seeded from [UserProfile] (+ auth contact + an optional [ResumeAnalysis]) and
/// then hand-editable before generating. Kept independent of the profile model
/// because a CV holds structured experience/education the profile doesn't.
class CvData extends Equatable {
  const CvData({
    this.fullName = '',
    this.headline = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.portfolioUrl = '',
    this.githubUrl = '',
    this.linkedinUrl = '',
    this.summary = '',
    this.experiences = const [],
    this.education = const [],
    this.skills = const [],
    this.projects = const [],
    this.targetRole = '',
  });

  // Contact / header.
  final String fullName;
  final String headline;
  final String email;
  final String phone;
  final String location;
  final String portfolioUrl;
  final String githubUrl;
  final String linkedinUrl;

  // Body.
  final String summary;
  final List<CvExperience> experiences;
  final List<CvEducation> education;
  final List<String> skills;
  final List<CvProject> projects;

  /// The role the CV targets — guides the AI enhancement, not printed.
  final String targetRole;

  bool get hasAnyLink =>
      portfolioUrl.isNotEmpty || githubUrl.isNotEmpty || linkedinUrl.isNotEmpty;

  /// True when there's essentially nothing to build a CV from yet.
  bool get isEmpty =>
      fullName.isEmpty &&
      summary.isEmpty &&
      experiences.every((e) => e.isBlank) &&
      education.every((e) => e.isBlank) &&
      skills.isEmpty;

  /// Seeds a CV from the user's profile, auth contact, and (optionally) the
  /// cached resume analysis — reusing everything already known so the user
  /// starts with a populated draft rather than a blank form.
  factory CvData.fromProfile(
    UserProfile profile, {
    AppUser? user,
    ResumeAnalysis? analysis,
  }) {
    return CvData(
      fullName: (profile.displayName ?? user?.displayName ?? '').trim(),
      headline: profile.headline ?? '',
      email: (user?.email ?? '').trim(),
      phone: (user?.phoneNumber ?? '').trim(),
      location: profile.location ?? '',
      portfolioUrl: profile.portfolioUrl ?? '',
      githubUrl: profile.githubUrl ?? '',
      linkedinUrl: profile.linkedinUrl ?? '',
      // Reuse the resume analysis summary when present, else the profile bio.
      summary: (analysis?.summary.trim().isNotEmpty ?? false)
          ? analysis!.summary.trim()
          : (profile.bio ?? ''),
      skills: List.unmodifiable(profile.skills),
      targetRole:
          profile.preferredJobTitles.isNotEmpty ? profile.preferredJobTitles.first : '',
    );
  }

  CvData copyWith({
    String? fullName,
    String? headline,
    String? email,
    String? phone,
    String? location,
    String? portfolioUrl,
    String? githubUrl,
    String? linkedinUrl,
    String? summary,
    List<CvExperience>? experiences,
    List<CvEducation>? education,
    List<String>? skills,
    List<CvProject>? projects,
    String? targetRole,
  }) =>
      CvData(
        fullName: fullName ?? this.fullName,
        headline: headline ?? this.headline,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        location: location ?? this.location,
        portfolioUrl: portfolioUrl ?? this.portfolioUrl,
        githubUrl: githubUrl ?? this.githubUrl,
        linkedinUrl: linkedinUrl ?? this.linkedinUrl,
        summary: summary ?? this.summary,
        experiences: experiences ?? this.experiences,
        education: education ?? this.education,
        skills: skills ?? this.skills,
        projects: projects ?? this.projects,
        targetRole: targetRole ?? this.targetRole,
      );

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'headline': headline,
        'email': email,
        'phone': phone,
        'location': location,
        'portfolioUrl': portfolioUrl,
        'githubUrl': githubUrl,
        'linkedinUrl': linkedinUrl,
        'summary': summary,
        'experiences': experiences.map((e) => e.toJson()).toList(),
        'education': education.map((e) => e.toJson()).toList(),
        'skills': skills,
        'projects': projects.map((e) => e.toJson()).toList(),
        'targetRole': targetRole,
      };

  factory CvData.fromJson(Map<String, dynamic> json) => CvData(
        fullName: _str(json['fullName'] ?? json['full_name']),
        headline: _str(json['headline']),
        email: _str(json['email']),
        phone: _str(json['phone']),
        location: _str(json['location']),
        portfolioUrl: _str(json['portfolioUrl'] ?? json['portfolio_url']),
        githubUrl: _str(json['githubUrl'] ?? json['github_url']),
        linkedinUrl: _str(json['linkedinUrl'] ?? json['linkedin_url']),
        summary: _str(json['summary']),
        experiences: _list(json['experiences'], CvExperience.fromJson),
        education: _list(json['education'], CvEducation.fromJson),
        skills: stringList(json['skills']),
        projects: _list(json['projects'], CvProject.fromJson),
        targetRole: _str(json['targetRole'] ?? json['target_role']),
      );

  /// Public so the nested models can share the list parser.
  static List<String> stringList(Object? value) {
    if (value is List) {
      final seen = <String>{};
      final out = <String>[];
      for (final e in value) {
        final t = e.toString().trim();
        if (t.isEmpty) continue;
        if (seen.add(t.toLowerCase())) out.add(t);
      }
      return List.unmodifiable(out);
    }
    if (value is String) return stringList(value.split(','));
    return const [];
  }

  static List<T> _list<T>(Object? value, T Function(Map<String, dynamic>) parse) {
    if (value is! List) return const [];
    return List.unmodifiable(value
        .whereType<Map>()
        .map((e) => parse(Map<String, dynamic>.from(e))));
  }

  @override
  List<Object?> get props => [
        fullName,
        headline,
        email,
        phone,
        location,
        portfolioUrl,
        githubUrl,
        linkedinUrl,
        summary,
        experiences,
        education,
        skills,
        projects,
        targetRole,
      ];
}

String _str(Object? value) => value?.toString().trim() ?? '';
