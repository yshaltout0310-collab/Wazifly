import 'package:equatable/equatable.dart';

/// A private employer note attached to an application.
///
/// Stored in a **separate** owner-private collection (`applicationNotes`) — never
/// embedded on the [Application] doc, which the applicant can read — so notes stay
/// private to the employer. [ownerUid] gates access (the security rule matches it
/// to `request.auth.uid`); [authorUid] records the specific recruiter and is
/// forward-ready for multi-recruiter teams.
class ApplicationNote extends Equatable {
  const ApplicationNote({
    required this.id,
    required this.applicationId,
    required this.ownerUid,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.authorUid,
  });

  final String id;
  final String applicationId;
  final String ownerUid;
  final String? authorUid;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;

  ApplicationNote copyWith({String? text, DateTime? updatedAt}) => ApplicationNote(
        id: id,
        applicationId: applicationId,
        ownerUid: ownerUid,
        authorUid: authorUid,
        text: text ?? this.text,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'applicationId': applicationId,
        'ownerUid': ownerUid,
        if (authorUid != null) 'authorUid': authorUid,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ApplicationNote.fromJson(Map<String, dynamic> json) {
    final created = _date(json['createdAt'] ?? json['created_at']);
    return ApplicationNote(
      id: (json['id'] ?? '').toString(),
      applicationId:
          (json['applicationId'] ?? json['application_id'] ?? '').toString(),
      ownerUid: (json['ownerUid'] ?? json['owner_uid'] ?? '').toString(),
      authorUid: json['authorUid']?.toString() ?? json['author_uid']?.toString(),
      text: (json['text'] ?? '').toString(),
      createdAt: created,
      updatedAt: json['updatedAt'] == null && json['updated_at'] == null
          ? created
          : _date(json['updatedAt'] ?? json['updated_at']),
    );
  }

  @override
  List<Object?> get props =>
      [id, applicationId, ownerUid, authorUid, text, createdAt, updatedAt];
}

DateTime _date(Object? raw) {
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
