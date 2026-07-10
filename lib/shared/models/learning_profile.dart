import 'package:equatable/equatable.dart';

/// The five learning-interest categories a job seeker can maintain.
///
/// A single enum (rather than five separate list fields) keeps the aggregate
/// small and makes Add/Edit/Delete/Search uniform across every category.
enum LearningCategory {
  careerPaths,
  skillsToLearn,
  technologies,
  industries,
  goals;

  static LearningCategory? fromName(Object? value) {
    if (value is! String) return null;
    final v = value.trim().toLowerCase();
    for (final c in LearningCategory.values) {
      if (c.name.toLowerCase() == v) return c;
    }
    return null;
  }
}

/// One learning interest — a labelled item in one [category], with an optional
/// free-text [note]. [id] is a deterministic FNV-1a fingerprint of
/// category+label so the same interest keeps a stable id across sessions and
/// duplicates collapse.
class LearningInterest extends Equatable {
  const LearningInterest({
    required this.id,
    required this.category,
    required this.label,
    required this.createdAt,
    this.note,
  });

  final String id;
  final LearningCategory category;
  final String label;
  final String? note;
  final DateTime createdAt;

  /// Builds an interest with a deterministic id from [category] + [label].
  factory LearningInterest.create({
    required LearningCategory category,
    required String label,
    required DateTime now,
    String? note,
  }) {
    final cleanLabel = label.trim();
    return LearningInterest(
      id: idFor(category, cleanLabel),
      category: category,
      label: cleanLabel,
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      createdAt: now,
    );
  }

  /// Deterministic id for a (category, label) pair — the de-dup key.
  static String idFor(LearningCategory category, String label) =>
      _fnv1a('${category.name}::${label.trim().toLowerCase()}');

  LearningInterest copyWith({String? label, String? note, bool clearNote = false}) {
    final newLabel = (label ?? this.label).trim();
    return LearningInterest(
      id: idFor(category, newLabel),
      category: category,
      label: newLabel,
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'label': label,
        if (note != null) 'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LearningInterest.fromJson(Map<String, dynamic> json) {
    final category =
        LearningCategory.fromName(json['category']) ?? LearningCategory.goals;
    final label = (json['label'] ?? '').toString().trim();
    final rawNote = json['note']?.toString().trim();
    return LearningInterest(
      id: (json['id'] ?? '').toString().isNotEmpty
          ? json['id'].toString()
          : idFor(category, label),
      category: category,
      label: label,
      note: (rawNote == null || rawNote.isEmpty) ? null : rawNote,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  @override
  List<Object?> get props => [id, category, label, note, createdAt];
}

/// The seeker's learning interests, persisted at `users/{uid}/learning/interests`.
///
/// A single small owned document (like `UserProfile`) holding one flat list of
/// [interests] grouped by category in the UI. Pure transitions
/// ([added]/[edited]/[removed]) compute a new profile that the controller
/// persists via `LearningProfileRepository.saveProfile` — the `CvDocument`
/// pattern. Anchors the future Mentors / Learning-Marketplace / Learning-Paths /
/// University-Partnership features under the same `users/{uid}/learning/*` space.
class LearningProfile extends Equatable {
  const LearningProfile({
    required this.uid,
    this.interests = const [],
    this.updatedAt,
  });

  final String uid;
  final List<LearningInterest> interests;
  final DateTime? updatedAt;

  static LearningProfile empty(String uid) => LearningProfile(uid: uid);

  bool get isEmpty => interests.isEmpty;

  /// Interests in [category], newest first.
  List<LearningInterest> byCategory(LearningCategory category) => interests
      .where((i) => i.category == category)
      .toList(growable: false)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Case-insensitive search over label + note (all categories).
  List<LearningInterest> search(String text) {
    final q = text.trim().toLowerCase();
    if (q.isEmpty) return interests;
    return interests
        .where((i) =>
            i.label.toLowerCase().contains(q) ||
            (i.note?.toLowerCase().contains(q) ?? false))
        .toList(growable: false);
  }

  bool contains(LearningCategory category, String label) {
    final id = LearningInterest.idFor(category, label);
    return interests.any((i) => i.id == id);
  }

  // --- Pure transitions (compute a new profile; the repo persists it) ---

  /// Adds [interest] (idempotent by id: a duplicate replaces the existing one).
  LearningProfile added(LearningInterest interest, DateTime now) {
    final next = interests.where((i) => i.id != interest.id).toList()
      ..add(interest);
    return copyWith(interests: next, updatedAt: now);
  }

  /// Replaces the interest with [oldId] by [updated] (id may change if the label
  /// changed). Drops any collision with the new id first.
  LearningProfile edited(String oldId, LearningInterest updated, DateTime now) {
    final next = interests
        .where((i) => i.id != oldId && i.id != updated.id)
        .toList()
      ..add(updated);
    return copyWith(interests: next, updatedAt: now);
  }

  LearningProfile removed(String id, DateTime now) => copyWith(
        interests: interests.where((i) => i.id != id).toList(),
        updatedAt: now,
      );

  LearningProfile copyWith({
    List<LearningInterest>? interests,
    DateTime? updatedAt,
  }) =>
      LearningProfile(
        uid: uid,
        interests: interests ?? this.interests,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'interests': interests.map((i) => i.toJson()).toList(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  factory LearningProfile.fromJson(Map<String, dynamic> json, {String? uid}) =>
      LearningProfile(
        uid: (json['uid'] ?? uid ?? '').toString(),
        interests: (json['interests'] is List)
            ? (json['interests'] as List)
                .whereType<Map>()
                .map((m) =>
                    LearningInterest.fromJson(Map<String, dynamic>.from(m)))
                .where((i) => i.label.isNotEmpty)
                .toList(growable: false)
            : const [],
        updatedAt:
            json['updatedAt'] == null ? null : _parseDate(json['updatedAt']),
      );

  @override
  List<Object?> get props => [uid, interests, updatedAt];
}

/// Deterministic 64-bit FNV-1a hash as hex (stable across sessions/isolates).
String _fnv1a(String input) {
  var hash = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  const mask = 0xFFFFFFFFFFFFFFFF;
  for (final unit in input.codeUnits) {
    hash = (hash ^ unit) & mask;
    hash = (hash * prime) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

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
