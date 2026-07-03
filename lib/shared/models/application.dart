import 'package:equatable/equatable.dart';

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

/// A single status-change entry in an application's history.
class ApplicationEvent extends Equatable {
  const ApplicationEvent({required this.status, required this.at});

  final ApplicationStatus status;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'at': at.toIso8601String(),
      };

  factory ApplicationEvent.fromJson(Map<String, dynamic> json) =>
      ApplicationEvent(
        status: applicationStatusFromName(json['status']),
        at: _parseDate(json['at']),
      );

  @override
  List<Object?> get props => [status, at];
}

/// A job application the user has submitted (mock apply today; the same shape
/// maps to a Firestore `users/{uid}/applications` document later).
///
/// Stores a **denormalized job snapshot** (title/company/location) captured at
/// apply time so the applications list needs no job lookup and history survives
/// even if the source job changes. [Application.fromJson] is defensive.
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

  /// Creates a fresh Pending application from a [job], captured at [now].
  factory Application.create({
    required String id,
    required Job job,
    required DateTime now,
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
        history: [ApplicationEvent(status: ApplicationStatus.pending, at: now)],
      );

  /// Returns a copy advanced to [status] at [at], appending a history event.
  Application withStatus(ApplicationStatus status, DateTime at) => copyWith(
        status: status,
        updatedAt: at,
        history: [...history, ApplicationEvent(status: status, at: at)],
      );

  Application copyWith({
    ApplicationStatus? status,
    DateTime? updatedAt,
    List<ApplicationEvent>? history,
    String? note,
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
  final s = raw?.toString();
  if (s == null || s.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
  return DateTime.tryParse(s) ??
      DateTime.fromMillisecondsSinceEpoch(int.tryParse(s) ?? 0);
}
