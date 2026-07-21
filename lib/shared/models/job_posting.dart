import 'package:equatable/equatable.dart';

import '../../features/employer/domain/employment_type.dart';
import '../../features/employer/domain/job_experience.dart';
import '../../features/employer/domain/job_status.dart';
import 'internship_details.dart';
import 'job.dart';
import 'salary_range.dart';

// SalaryRange now lives in its own file so the seeker [Job] can carry it too;
// re-exported here so existing `import 'job_posting.dart'` users are unaffected.
export 'salary_range.dart' show SalaryRange;

/// Analytics foundation for a posting. Counters default to zero; the nullable
/// timestamps ([firstPublishedAt]/[lastViewedAt]/[lastApplicationAt]) are
/// **not populated in this milestone** but let the model evolve for future
/// analytics with no refactor.
class JobMetrics extends Equatable {
  const JobMetrics({
    this.views = 0,
    this.applicationsCount = 0,
    this.firstPublishedAt,
    this.lastViewedAt,
    this.lastApplicationAt,
  });

  final int views;
  final int applicationsCount;
  final DateTime? firstPublishedAt;
  final DateTime? lastViewedAt;
  final DateTime? lastApplicationAt;

  static const JobMetrics zero = JobMetrics();

  Map<String, dynamic> toJson() => {
        'views': views,
        'applicationsCount': applicationsCount,
        'firstPublishedAt': firstPublishedAt?.toIso8601String(),
        'lastViewedAt': lastViewedAt?.toIso8601String(),
        'lastApplicationAt': lastApplicationAt?.toIso8601String(),
      };

  factory JobMetrics.fromJson(Map<String, dynamic> json) => JobMetrics(
        views: _int(json['views']),
        applicationsCount:
            _int(json['applicationsCount'] ?? json['applications_count']),
        firstPublishedAt:
            _date(json['firstPublishedAt'] ?? json['first_published_at']),
        lastViewedAt: _date(json['lastViewedAt'] ?? json['last_viewed_at']),
        lastApplicationAt:
            _date(json['lastApplicationAt'] ?? json['last_application_at']),
      );

  @override
  List<Object?> get props =>
      [views, applicationsCount, firstPublishedAt, lastViewedAt, lastApplicationAt];
}

/// One entry in a posting's status-change history (Draft → Published → …).
///
/// A lightweight audit trail mirroring `ApplicationEvent`; retained now so a
/// future timeline UI needs no model redesign.
class JobStatusChange extends Equatable {
  const JobStatusChange({
    required this.status,
    required this.at,
    this.by,
    this.reason,
  });

  final JobStatus status;
  final DateTime at;

  /// Actor uid (audit / future multi-recruiter).
  final String? by;

  /// Optional note (e.g. an archive reason).
  final String? reason;

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'at': at.toIso8601String(),
        'by': by,
        'reason': reason,
      };

  factory JobStatusChange.fromJson(Map<String, dynamic> json) => JobStatusChange(
        status: JobStatus.fromName(json['status']),
        at: _date(json['at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        by: _str(json['by']),
        reason: _str(json['reason']),
      );

  @override
  List<Object?> get props => [status, at, by, reason];
}

/// An employer-owned job posting — the **management** superset of the public
/// [Job]. Persisted at `jobs/{jobId}` in Firestore. Carries lifecycle,
/// availability, salary, openings, soft-delete, analytics ([metrics]), status
/// [statusHistory], and audit ([createdBy]/[updatedBy]) — none of which belong
/// on the seeker-facing [Job]. Denormalizes [companyName] (like `Application`)
/// so consumers need no company lookup.
///
/// [toJob] projects to the existing shared [Job] so the preview + any future
/// seeker consumption reuse the exact public model — reuse by projection, not
/// duplication. Defensive [fromJson] tolerates snake_case / bad enums /
/// ISO+millis+Timestamp dates.
class JobPosting extends Equatable {
  const JobPosting({
    required this.id,
    required this.companyId,
    required this.ownerUid,
    this.companyName = '',
    this.title = '',
    this.description = '',
    this.requiredSkills = const [],
    this.location = '',
    this.remote = false,
    this.employmentType,
    this.experience,
    this.salary,
    this.openings,
    this.internship,
    this.trainsBeginners = false,
    this.status = JobStatus.draft,
    this.publishedAt,
    this.opensAt,
    this.expiresAt,
    this.archiveReason,
    this.deletedAt,
    this.metrics = JobMetrics.zero,
    this.statusHistory = const [],
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String companyId;
  final String ownerUid;
  final String companyName;

  // Public content (projected to Job).
  final String title;
  final String description;
  final List<String> requiredSkills;
  final String location;
  final bool remote;
  final EmploymentType? employmentType;
  final JobExperience? experience;
  final SalaryRange? salary;

  /// Number of open positions (optional; defaults to 1 for display).
  final int? openings;

  /// Optional internship metadata (present only when this posting is an
  /// internship). Embedded like [salary]/[metrics] — additive and defensive.
  final InternshipDetails? internship;

  /// Employer opt-in marking the role beginner-friendly ("Train Beginners").
  /// Independent of internship status; drives a visible badge + a future
  /// beginner-weighted recommendation signal.
  final bool trainsBeginners;

  // Lifecycle.
  final JobStatus status;
  final DateTime? publishedAt;
  final DateTime? opensAt;
  final DateTime? expiresAt;
  final String? archiveReason;

  /// Soft delete: non-null means removed from lists but retained in Firestore
  /// (so applications / analytics / auditing stay intact).
  final DateTime? deletedAt;

  final JobMetrics metrics;
  final List<JobStatusChange> statusHistory;

  // Audit (multi-recruiter ready).
  final String? createdBy;
  final String? updatedBy;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDeleted => deletedAt != null;
  bool get isLive => status == JobStatus.published && !isDeleted;
  bool get isEditable => !isDeleted;
  int get displayOpenings => openings ?? 1;

  /// Whether this posting is an internship (by employment type).
  bool get isInternship => employmentType == EmploymentType.internship;

  bool isExpiredAt(DateTime now) =>
      expiresAt != null && expiresAt!.isBefore(now);
  bool isScheduledAt(DateTime now) =>
      opensAt != null && opensAt!.isAfter(now);

  /// Can this posting be published from its current status?
  bool get isPublishable => status.canTransitionTo(JobStatus.published);

  /// A blank draft seeded with identity + an initial history entry.
  factory JobPosting.create({
    required String id,
    required String companyId,
    required String ownerUid,
    String companyName = '',
    required DateTime now,
    String? by,
  }) =>
      JobPosting(
        id: id,
        companyId: companyId,
        ownerUid: ownerUid,
        companyName: companyName,
        status: JobStatus.draft,
        metrics: JobMetrics.zero,
        statusHistory: [JobStatusChange(status: JobStatus.draft, at: now, by: by)],
        createdBy: by,
        updatedBy: by,
        createdAt: now,
        updatedAt: now,
      );

  /// The public projection consumed by the preview + (future) seeker platform.
  ///
  /// Projects the internship metadata + [trainsBeginners] so the seeker's
  /// `JobDetailView` and the internship browse render them from the shared [Job]
  /// — reuse by projection, not duplication. Internship details are carried only
  /// for internships (so a normal job never leaks a stray internship block).
  Job toJob() => Job(
        id: id,
        title: title,
        company: companyName,
        location: location,
        employmentType: employmentType?.canonical ?? '',
        seniority: experience?.canonical ?? '',
        description: description,
        requiredSkills: requiredSkills,
        remote: remote,
        salary: salary,
        internship:
            isInternship && internship != null && !internship!.isEmpty
                ? internship
                : null,
        trainsBeginners: trainsBeginners,
      );

  /// Transitions to [next], appending a history entry and stamping the audit /
  /// lifecycle fields. Sets [publishedAt] on first publish; sets/clears
  /// [archiveReason] on archive/reopen.
  JobPosting withStatus(
    JobStatus next, {
    required DateTime at,
    String? by,
    String? reason,
  }) =>
      copyWith(
        status: next,
        publishedAt: next == JobStatus.published ? (publishedAt ?? at) : publishedAt,
        archiveReason: next == JobStatus.archived ? reason : null,
        clearArchiveReason: next != JobStatus.archived,
        statusHistory: [
          ...statusHistory,
          JobStatusChange(status: next, at: at, by: by, reason: reason),
        ],
        updatedBy: by,
        updatedAt: at,
      );

  /// Soft-deletes (retains the document; hidden from lists).
  JobPosting softDeleted({required DateTime at, String? by}) => copyWith(
        deletedAt: at,
        updatedBy: by,
        updatedAt: at,
      );

  /// A fresh draft copy for the "Duplicate" action (new id, cleared lifecycle /
  /// metrics / audit trail; title suffixed).
  JobPosting duplicated({
    required String id,
    required DateTime now,
    String? by,
    String copySuffix = ' (Copy)',
  }) =>
      JobPosting(
        id: id,
        companyId: companyId,
        ownerUid: ownerUid,
        companyName: companyName,
        title: title.isEmpty ? title : '$title$copySuffix',
        description: description,
        requiredSkills: requiredSkills,
        location: location,
        remote: remote,
        employmentType: employmentType,
        experience: experience,
        salary: salary,
        openings: openings,
        internship: internship,
        trainsBeginners: trainsBeginners,
        status: JobStatus.draft,
        metrics: JobMetrics.zero,
        statusHistory: [JobStatusChange(status: JobStatus.draft, at: now, by: by)],
        createdBy: by,
        updatedBy: by,
        createdAt: now,
        updatedAt: now,
      );

  JobPosting copyWith({
    String? id,
    String? companyId,
    String? ownerUid,
    String? companyName,
    String? title,
    String? description,
    List<String>? requiredSkills,
    String? location,
    bool? remote,
    EmploymentType? employmentType,
    JobExperience? experience,
    SalaryRange? salary,
    int? openings,
    InternshipDetails? internship,
    bool clearInternship = false,
    bool? trainsBeginners,
    JobStatus? status,
    DateTime? publishedAt,
    DateTime? opensAt,
    DateTime? expiresAt,
    String? archiveReason,
    bool clearArchiveReason = false,
    DateTime? deletedAt,
    JobMetrics? metrics,
    List<JobStatusChange>? statusHistory,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      JobPosting(
        id: id ?? this.id,
        companyId: companyId ?? this.companyId,
        ownerUid: ownerUid ?? this.ownerUid,
        companyName: companyName ?? this.companyName,
        title: title ?? this.title,
        description: description ?? this.description,
        requiredSkills: requiredSkills ?? this.requiredSkills,
        location: location ?? this.location,
        remote: remote ?? this.remote,
        employmentType: employmentType ?? this.employmentType,
        experience: experience ?? this.experience,
        salary: salary ?? this.salary,
        openings: openings ?? this.openings,
        internship: clearInternship ? null : (internship ?? this.internship),
        trainsBeginners: trainsBeginners ?? this.trainsBeginners,
        status: status ?? this.status,
        publishedAt: publishedAt ?? this.publishedAt,
        opensAt: opensAt ?? this.opensAt,
        expiresAt: expiresAt ?? this.expiresAt,
        archiveReason:
            clearArchiveReason ? archiveReason : (archiveReason ?? this.archiveReason),
        deletedAt: deletedAt ?? this.deletedAt,
        metrics: metrics ?? this.metrics,
        statusHistory: statusHistory ?? this.statusHistory,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'ownerUid': ownerUid,
        'companyName': companyName,
        'title': title,
        'description': description,
        'requiredSkills': requiredSkills,
        'location': location,
        'remote': remote,
        'employmentType': employmentType?.name,
        'experience': experience?.name,
        'salary': salary?.toJson(),
        'openings': openings,
        if (internship != null) 'internship': internship!.toJson(),
        'trainsBeginners': trainsBeginners,
        'status': status.name,
        'publishedAt': publishedAt?.toIso8601String(),
        'opensAt': opensAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'archiveReason': archiveReason,
        'deletedAt': deletedAt?.toIso8601String(),
        'metrics': metrics.toJson(),
        'statusHistory': statusHistory.map((e) => e.toJson()).toList(),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
      };

  factory JobPosting.fromJson(Map<String, dynamic> json) {
    final companyId = _str(json['companyId'] ?? json['company_id']) ?? '';
    return JobPosting(
      id: _str(json['id']) ?? '',
      companyId: companyId,
      ownerUid: _str(json['ownerUid'] ?? json['owner_uid']) ?? companyId,
      companyName: _str(json['companyName'] ?? json['company_name']) ?? '',
      title: _str(json['title']) ?? '',
      description: _str(json['description']) ?? '',
      requiredSkills:
          _stringList(json['requiredSkills'] ?? json['required_skills'] ?? json['skills']),
      location: _str(json['location']) ?? '',
      remote: json['remote'] == true,
      employmentType:
          EmploymentType.fromName(json['employmentType'] ?? json['employment_type']),
      experience: JobExperience.fromName(json['experience']),
      salary: json['salary'] is Map
          ? SalaryRange.fromJson(Map<String, dynamic>.from(json['salary'] as Map))
          : null,
      openings: _intOrNull(json['openings']),
      internship: json['internship'] is Map
          ? InternshipDetails.fromJson(
              Map<String, dynamic>.from(json['internship'] as Map))
          : null,
      trainsBeginners:
          json['trainsBeginners'] == true || json['trains_beginners'] == true,
      status: JobStatus.fromName(json['status']),
      publishedAt: _date(json['publishedAt'] ?? json['published_at']),
      opensAt: _date(json['opensAt'] ?? json['opens_at']),
      expiresAt: _date(json['expiresAt'] ?? json['expires_at']),
      archiveReason: _str(json['archiveReason'] ?? json['archive_reason']),
      deletedAt: _date(json['deletedAt'] ?? json['deleted_at']),
      metrics: json['metrics'] is Map
          ? JobMetrics.fromJson(Map<String, dynamic>.from(json['metrics'] as Map))
          : JobMetrics.zero,
      statusHistory: _list(json['statusHistory'] ?? json['status_history'],
          JobStatusChange.fromJson),
      createdBy: _str(json['createdBy'] ?? json['created_by']),
      updatedBy: _str(json['updatedBy'] ?? json['updated_by']),
      createdAt: _date(json['createdAt'] ?? json['created_at']),
      updatedAt: _date(json['updatedAt'] ?? json['updated_at']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        ownerUid,
        companyName,
        title,
        description,
        requiredSkills,
        location,
        remote,
        employmentType,
        experience,
        salary,
        openings,
        internship,
        trainsBeginners,
        status,
        publishedAt,
        opensAt,
        expiresAt,
        archiveReason,
        deletedAt,
        metrics,
        statusHistory,
        createdBy,
        updatedBy,
      ];
}

// --- shared parsers ---

String? _str(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

int _int(Object? raw) =>
    raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '') ?? 0;

int? _intOrNull(Object? raw) {
  if (raw == null) return null;
  return raw is num ? raw.toInt() : int.tryParse(raw.toString());
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
