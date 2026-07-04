import 'package:equatable/equatable.dart';

import '../../features/employer/domain/company_size.dart';
import '../../features/employer/domain/company_verification_status.dart';
import '../../features/employer/domain/industry.dart';

/// The set of company attributes tracked by the completion indicator. The UI
/// maps each entry to a localized label when nudging the employer to fill gaps.
enum CompanyField {
  name,
  logo,
  industry,
  size,
  website,
  headquarters,
  description,
  contactEmail,
}

/// An AI-generated assessment of company-profile quality.
///
/// **Not produced in Milestone 1** — the field is null and unused in the UI. It
/// lives here now (Firestore-ready, defensively parsed) so a future
/// "Company Strength / Profile Quality" AI feature can populate it via the
/// repository with **no model refactor** (mirrors the report-ready Interview
/// models).
class CompanyStrength extends Equatable {
  const CompanyStrength({
    this.score = 0,
    this.summary = '',
    this.strengths = const [],
    this.improvements = const [],
    this.analyzedAt,
  });

  /// 0–100 profile-quality score.
  final int score;
  final String summary;
  final List<String> strengths;
  final List<String> improvements;
  final DateTime? analyzedAt;

  bool get isEmpty =>
      summary.isEmpty && strengths.isEmpty && improvements.isEmpty;

  Map<String, dynamic> toJson() => {
        'score': score,
        'summary': summary,
        'strengths': strengths,
        'improvements': improvements,
        'analyzedAt': analyzedAt?.toIso8601String(),
      };

  factory CompanyStrength.fromJson(Map<String, dynamic> json) => CompanyStrength(
        score: _int(json['score']),
        summary: _str(json['summary']) ?? '',
        strengths: _stringList(json['strengths']),
        improvements: _stringList(json['improvements']),
        analyzedAt: _date(json['analyzedAt'] ?? json['analyzed_at']),
      );

  @override
  List<Object?> get props =>
      [score, summary, strengths, improvements, analyzedAt];
}

/// The employer's company, persisted at `companies/{companyId}` in Firestore
/// (`companyId == ownerUid` in Milestone 1 — one employer, one company).
///
/// Deliberately decoupled from the job-seeker [UserProfile]: the employer's
/// identity comes from Firebase Auth, while this holds the company data. All
/// fields beyond the keys are optional and (for the tracked subset) feed the
/// completion indicator. Defensive [fromJson] tolerates snake_case, missing /
/// mistyped fields, and ISO / millis / Timestamp dates so partial docs never
/// throw. Shaped for reuse by future job posting + a public company page
/// ([companySlug]) and an AI profile-quality score ([strength]).
class Company extends Equatable {
  const Company({
    required this.companyId,
    required this.ownerUid,
    this.name,
    this.industry,
    this.size,
    this.website,
    this.headquarters,
    this.description,
    this.contactEmail,
    this.contactPhone,
    this.logoUrl,
    this.companySlug,
    this.verificationStatus = CompanyVerificationStatus.pending,
    this.linkedinUrl,
    this.xUrl,
    this.facebookUrl,
    this.strength,
    this.createdAt,
    this.updatedAt,
  });

  final String companyId;
  final String ownerUid;

  final String? name;
  final Industry? industry;
  final CompanySize? size;
  final String? website;
  final String? headquarters;
  final String? description;

  // Contact information.
  final String? contactEmail;
  final String? contactPhone;

  final String? logoUrl;

  /// URL-safe handle for a future public company page (`/c/{slug}`). Stored now
  /// so public URLs work later without a migration; auto-derived from [name] on
  /// save when empty.
  final String? companySlug;

  /// Platform verification state (no Milestone 1 UI).
  final CompanyVerificationStatus verificationStatus;

  // Optional social links (future use).
  final String? linkedinUrl;
  final String? xUrl;
  final String? facebookUrl;

  /// Optional AI profile-quality assessment (null in Milestone 1).
  final CompanyStrength? strength;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// An empty company carrying only its keys.
  factory Company.empty(String ownerUid) =>
      Company(companyId: ownerUid, ownerUid: ownerUid);

  bool get hasLogo => _isFilled(logoUrl);
  bool get hasAnySocial =>
      _isFilled(linkedinUrl) || _isFilled(xUrl) || _isFilled(facebookUrl);

  /// Fields the employer still hasn't filled, in display order.
  List<CompanyField> get missingFields => [
        if (!_isFilled(name)) CompanyField.name,
        if (!hasLogo) CompanyField.logo,
        if (industry == null) CompanyField.industry,
        if (size == null) CompanyField.size,
        if (!_isFilled(website)) CompanyField.website,
        if (!_isFilled(headquarters)) CompanyField.headquarters,
        if (!_isFilled(description)) CompanyField.description,
        if (!_isFilled(contactEmail)) CompanyField.contactEmail,
      ];

  /// Completion ratio in `[0, 1]` across all tracked [CompanyField]s.
  double get completion {
    const total = 8; // must match the count in [missingFields]
    final filled = total - missingFields.length;
    return filled / total;
  }

  /// Completion as a rounded percentage `[0, 100]`.
  int get completionPercent => (completion * 100).round();

  Company copyWith({
    String? companyId,
    String? ownerUid,
    String? name,
    Industry? industry,
    CompanySize? size,
    String? website,
    String? headquarters,
    String? description,
    String? contactEmail,
    String? contactPhone,
    String? logoUrl,
    String? companySlug,
    CompanyVerificationStatus? verificationStatus,
    String? linkedinUrl,
    String? xUrl,
    String? facebookUrl,
    CompanyStrength? strength,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      companyId: companyId ?? this.companyId,
      ownerUid: ownerUid ?? this.ownerUid,
      name: name ?? this.name,
      industry: industry ?? this.industry,
      size: size ?? this.size,
      website: website ?? this.website,
      headquarters: headquarters ?? this.headquarters,
      description: description ?? this.description,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      logoUrl: logoUrl ?? this.logoUrl,
      companySlug: companySlug ?? this.companySlug,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      xUrl: xUrl ?? this.xUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      strength: strength ?? this.strength,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serializes the user-editable fields (the repository manages
  /// `createdAt`/`updatedAt` via server timestamps, so they're omitted here).
  Map<String, dynamic> toJson() => {
        'companyId': companyId,
        'ownerUid': ownerUid,
        'name': name,
        'industry': industry?.name,
        'size': size?.name,
        'website': website,
        'headquarters': headquarters,
        'description': description,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'logoUrl': logoUrl,
        'companySlug': companySlug,
        'verificationStatus': verificationStatus.name,
        'linkedinUrl': linkedinUrl,
        'xUrl': xUrl,
        'facebookUrl': facebookUrl,
        'strength': strength?.toJson(),
      };

  factory Company.fromJson(Map<String, dynamic> json) {
    final ownerUid = _str(json['ownerUid'] ?? json['owner_uid']) ?? '';
    return Company(
      companyId: _str(json['companyId'] ?? json['company_id']) ?? ownerUid,
      ownerUid: ownerUid,
      name: _str(json['name']),
      industry: Industry.fromName(json['industry']),
      size: CompanySize.fromName(json['size'] ?? json['companySize']),
      website: _str(json['website']),
      headquarters: _str(json['headquarters'] ?? json['hq']),
      description: _str(json['description']),
      contactEmail: _str(json['contactEmail'] ?? json['contact_email']),
      contactPhone: _str(json['contactPhone'] ?? json['contact_phone']),
      logoUrl: _str(json['logoUrl'] ?? json['logo_url']),
      companySlug: _str(json['companySlug'] ?? json['company_slug'] ?? json['slug']),
      verificationStatus: CompanyVerificationStatus.fromName(
          json['verificationStatus'] ?? json['verification_status']),
      linkedinUrl: _str(json['linkedinUrl'] ?? json['linkedin_url']),
      xUrl: _str(json['xUrl'] ?? json['x_url'] ?? json['twitterUrl']),
      facebookUrl: _str(json['facebookUrl'] ?? json['facebook_url']),
      strength: json['strength'] is Map
          ? CompanyStrength.fromJson(
              Map<String, dynamic>.from(json['strength'] as Map))
          : null,
      createdAt: _date(json['createdAt'] ?? json['created_at']),
      updatedAt: _date(json['updatedAt'] ?? json['updated_at']),
    );
  }

  /// Derives a URL-safe slug from a company name (lowercase, alphanumerics +
  /// single dashes). Best-effort / non-unique in Milestone 1.
  static String slugify(String name) {
    final s = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp('^-+|-+\$'), '');
    return s;
  }

  static bool _isFilled(String? value) => value != null && value.trim().isNotEmpty;

  @override
  List<Object?> get props => [
        companyId,
        ownerUid,
        name,
        industry,
        size,
        website,
        headquarters,
        description,
        contactEmail,
        contactPhone,
        logoUrl,
        companySlug,
        verificationStatus,
        linkedinUrl,
        xUrl,
        facebookUrl,
        strength,
      ];
}

// --- shared parsers ---

String? _str(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

int _int(Object? raw) {
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
