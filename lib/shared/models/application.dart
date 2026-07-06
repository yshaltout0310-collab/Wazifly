import 'package:equatable/equatable.dart';

import 'applicant_snapshot.dart';
import 'job.dart';

/// Lifecycle status of a job application.
enum ApplicationStatus { pending, reviewed, interview, accepted, rejected }

/// Parses a status name defensively (unknown/missing → [ApplicationStatus.pending]).
ApplicationStatus applicationStatusFromName(Object? raw) {
  final name = raw?.toString().trim().toLowerCase();
  for (final s in ApplicationStatus.values) {
    if (s.name == name) return s;
  }
  return ApplicationStatus.pending;
}

/// Recruitment channel an application arrived through. Defaults to
/// [ApplicationSource.careerBridge]; the field is forward-ready for future
/// referral / external-import / company-website ingestion.
enum ApplicationSource { careerBridge, referral, externalImport, companyWebsite }

/// Parses a source name defensively (unknown/missing → [ApplicationSource.careerBridge]).
ApplicationSource applicationSourceFromName(Object? raw) {
  final name = raw?.toString().trim().toLowerCase();
  for (final s in ApplicationSource.values) {
    if (s.name.toLowerCase() == name) return s;
  }
  return ApplicationSource.careerBridge;
}

/// A single status-change entry in an application's history.
///
/// [by] (actor uid) and [note] (e.g. a rejection reason) are optional audit
/// fields — forward-ready for multi-recruiter attribution — and append-only:
/// every status change adds a new event rather than mutating a previous one.
class ApplicationEvent extends Equatable {
  const ApplicationEvent({
    required this.status,
    required this.at,
    this.by,
    this.note,
  });

  final ApplicationStatus status;
  final DateTime at;
  final String? by;
  final String? note;

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'at': at.toIso8601String(),
        if (by != null) 'by': by,
        if (note != null) 'note': note,
      };

  factory ApplicationEvent.fromJson(Map<String, dynamic> json) =>
      ApplicationEvent(
        status: applicationStatusFromName(json['status']),
        at: _parseDate(json['at']),
        by: json['by']?.toString(),
        note: json['note']?.toString(),
      );

  @override
  List<Object?> get props => [status, at, by, note];
}

/// A job application.
///
/// This is the **single shared model** for both surfaces: the seeker's
/// Applications Center reads it by [applicantUid]; the employer's Applicants
/// Management reads it by [ownerUid] (the job owner). Both parties see the same
/// [history], so an employer status change is intrinsically the same event the
/// seeker's timeline renders — no bridge type is needed.
///
/// Carries a **denormalized job snapshot** (title/company/location) plus, for the
/// employer view, a denormalized [applicant] snapshot captured at apply time (see
/// [ApplicantSnapshot] for why). [Application.fromJson] is defensive.
class Application extends Equatable {
  const Application({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.location,
    required this.status,
    required this.appliedAt,
    required this.updatedAt,
    required this.history,
    this.note,
    // employer-side identity / routing (denormalized at apply time)
    this.applicantUid = '',
    this.ownerUid = '',
    this.companyId = '',
    this.companyName = '',
    this.source = ApplicationSource.careerBridge,
    this.applicant,
  });

  final String id;
  final String jobId;
  final String jobTitle;
  final String company;
  final String location;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final DateTime updatedAt;
  final List<ApplicationEvent> history;
  final String? note;

  /// Applicant (seeker) uid — the doc's owner on the seeker side.
  final String applicantUid;

  /// Job owner (employer) uid — the doc's owner on the employer side; the
  /// employer Applicants query filters on this to match the security rule.
  final String ownerUid;
  final String companyId;
  final String companyName;

  /// Recruitment channel (defaults to CareerBridge).
  final ApplicationSource source;

  /// The employer-facing applicant snapshot (null for legacy / seeker-only apps).
  final ApplicantSnapshot? applicant;

  /// Creates a fresh Pending application from a [job], captured at [now].
  ///
  /// The employer-side identity fields + [applicant] snapshot are optional so the
  /// existing seeker mock-apply keeps working unchanged; a real Firestore-backed
  /// apply passes them (assembled seeker-side from the current user's own data).
  factory Application.create({
    required String id,
    required Job job,
    required DateTime now,
    String applicantUid = '',
    String ownerUid = '',
    String companyId = '',
    String companyName = '',
    ApplicationSource source = ApplicationSource.careerBridge,
    ApplicantSnapshot? applicant,
  }) =>
      Application(
        id: id,
        jobId: job.id,
        jobTitle: job.title,
        company: job.company,
        location: job.location,
        status: ApplicationStatus.pending,
        appliedAt: now,
        updatedAt: now,
        history: [
          ApplicationEvent(
              status: ApplicationStatus.pending,
              at: now,
              by: applicantUid.isEmpty ? null : applicantUid),
        ],
        applicantUid: applicantUid,
        ownerUid: ownerUid,
        companyId: companyId,
        companyName: companyName,
        source: source,
        applicant: applicant,
      );

  /// Returns a copy advanced to [status] at [at], **appending** a history event
  /// (never replacing prior events). [by] records the acting employer/recruiter.
  Application withStatus(
    ApplicationStatus status,
    DateTime at, {
    String? by,
    String? note,
  }) =>
      copyWith(
        status: status,
        updatedAt: at,
        history: [
          ...history,
          ApplicationEvent(status: status, at: at, by: by, note: note),
        ],
      );

  Application copyWith({
    ApplicationStatus? status,
    DateTime? updatedAt,
    List<ApplicationEvent>? history,
    String? note,
    String? applicantUid,
    String? ownerUid,
    String? companyId,
    String? companyName,
    ApplicationSource? source,
    ApplicantSnapshot? applicant,
  }) =>
      Application(
        id: id,
        jobId: jobId,
        jobTitle: jobTitle,
        company: company,
        location: location,
        status: status ?? this.status,
        appliedAt: appliedAt,
        updatedAt: updatedAt ?? this.updatedAt,
        history: history ?? this.history,
        note: note ?? this.note,
        applicantUid: applicantUid ?? this.applicantUid,
        ownerUid: ownerUid ?? this.ownerUid,
        companyId: companyId ?? this.companyId,
        companyName: companyName ?? this.companyName,
        source: source ?? this.source,
        applicant: applicant ?? this.applicant,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'jobId': jobId,
        'jobTitle': jobTitle,
        'company': company,
        'location': location,
        'status': status.name,
        'appliedAt': appliedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'history': history.map((e) => e.toJson()).toList(),
        if (note != null) 'note': note,
        'applicantUid': applicantUid,
        'ownerUid': ownerUid,
        'companyId': companyId,
        'companyName': companyName,
        'source': source.name,
        if (applicant != null) 'applicant': applicant!.toJson(),
      };

  factory Application.fromJson(Map<String, dynamic> json) {
    final applied = _parseDate(json['appliedAt']);
    return Application(
      id: (json['id'] ?? '').toString(),
      jobId: (json['jobId'] ?? json['job_id'] ?? '').toString(),
      jobTitle: (json['jobTitle'] ?? json['job_title'] ?? '').toString(),
      company: (json['company'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      status: applicationStatusFromName(json['status']),
      appliedAt: applied,
      updatedAt: json['updatedAt'] == null
          ? applied
          : _parseDate(json['updatedAt']),
      history: _parseHistory(json['history']),
      note: json['note']?.toString(),
      applicantUid: (json['applicantUid'] ?? json['applicant_uid'] ?? '').toString(),
      ownerUid: (json['ownerUid'] ?? json['owner_uid'] ?? '').toString(),
      companyId: (json['companyId'] ?? json['company_id'] ?? '').toString(),
      companyName: (json['companyName'] ?? json['company_name'] ?? '').toString(),
      source: applicationSourceFromName(json['source']),
      applicant: json['applicant'] is Map
          ? ApplicantSnapshot.fromJson(
              Map<String, dynamic>.from(json['applicant'] as Map))
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        jobId,
        jobTitle,
        company,
        location,
        status,
        appliedAt,
        updatedAt,
        history,
        note,
        applicantUid,
        ownerUid,
        companyId,
        companyName,
        source,
        applicant,
      ];

  static List<ApplicationEvent> _parseHistory(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ApplicationEvent.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }
}

/// Tolerates ISO-8601 strings and epoch millis (and null → epoch 0). A Firestore
/// repository converts `Timestamp` to a millis int / ISO string before parsing.
DateTime _parseDate(Object? raw) {
  if (raw is DateTime) return raw;
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  // Firestore Timestamp (duck-typed so `shared/` needn't import cloud_firestore).
  try {
    final d = (raw as dynamic).toDate();
    if (d is DateTime) return d;
  } catch (_) {/* not a Timestamp */}
  final s = raw?.toString();
  if (s == null || s.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
  return DateTime.tryParse(s) ??
      DateTime.fromMillisecondsSinceEpoch(int.tryParse(s) ?? 0);
}
