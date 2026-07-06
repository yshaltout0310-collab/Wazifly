import 'package:equatable/equatable.dart';

/// The kind of employer action recorded in the activity log.
enum EmployerActivityType {
  statusReview,
  statusInterview,
  statusAccept,
  statusReject,
  statusReopen,
  noteAdded,
  noteEdited,
  noteDeleted,
}

EmployerActivityType employerActivityTypeFromName(Object? raw) {
  final name = raw?.toString().trim();
  for (final t in EmployerActivityType.values) {
    if (t.name == name) return t;
  }
  return EmployerActivityType.statusReview;
}

/// A recorded significant employer action — the **foundation for future employer
/// activity auditing** (Milestone 3 addition #2).
///
/// Kept intentionally minimal but complete so review/interview/accept/reject and
/// note create/edit/delete can be logged now (fire-and-forget) and surfaced in a
/// future audit UI without a data-model redesign. [ownerUid] gates access (an
/// owner-private collection); [actorUid] records the specific recruiter for
/// multi-recruiter teams. Optional [from]/[to] describe a status transition and
/// [targetId] references a related entity (e.g. a note id).
class EmployerActivity extends Equatable {
  const EmployerActivity({
    required this.id,
    required this.ownerUid,
    required this.type,
    required this.applicationId,
    required this.at,
    this.actorUid,
    this.from,
    this.to,
    this.targetId,
  });

  final String id;
  final String ownerUid;
  final String? actorUid;
  final EmployerActivityType type;
  final String applicationId;
  final DateTime at;

  /// Status transition endpoints (for status.* activities).
  final String? from;
  final String? to;

  /// Related entity id (e.g. the note id for note.* activities).
  final String? targetId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerUid': ownerUid,
        if (actorUid != null) 'actorUid': actorUid,
        'type': type.name,
        'applicationId': applicationId,
        'at': at.toIso8601String(),
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (targetId != null) 'targetId': targetId,
      };

  factory EmployerActivity.fromJson(Map<String, dynamic> json) => EmployerActivity(
        id: (json['id'] ?? '').toString(),
        ownerUid: (json['ownerUid'] ?? json['owner_uid'] ?? '').toString(),
        actorUid: json['actorUid']?.toString() ?? json['actor_uid']?.toString(),
        type: employerActivityTypeFromName(json['type']),
        applicationId:
            (json['applicationId'] ?? json['application_id'] ?? '').toString(),
        at: _date(json['at']),
        from: json['from']?.toString(),
        to: json['to']?.toString(),
        targetId: json['targetId']?.toString() ?? json['target_id']?.toString(),
      );

  @override
  List<Object?> get props =>
      [id, ownerUid, actorUid, type, applicationId, at, from, to, targetId];
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
