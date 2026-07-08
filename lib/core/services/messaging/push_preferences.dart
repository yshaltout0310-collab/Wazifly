import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A push-notification delivery category. These map to future FCM topics /
/// backend targeting. Distinct from the in-app settings `NotificationPreferences`
/// (which drives the Settings UI toggles) — this is the delivery-layer
/// foundation, kept separate to avoid refactoring the settings feature now. A
/// future milestone can map settings toggles → these categories.
enum PushCategory {
  jobRecommendations,
  applicationUpdates,
  interviewReminders,
  employerNotifications,
}

/// Per-category push preferences, gated by a [master] switch. Defensive JSON so
/// it round-trips to a future Firestore `users/{uid}` field with no changes.
class PushPreferences extends Equatable {
  const PushPreferences({
    this.master = true,
    this.jobRecommendations = true,
    this.applicationUpdates = true,
    this.interviewReminders = true,
    this.employerNotifications = true,
  });

  final bool master;
  final bool jobRecommendations;
  final bool applicationUpdates;
  final bool interviewReminders;
  final bool employerNotifications;

  static const PushPreferences defaults = PushPreferences();

  /// Whether [category] should deliver — always false when [master] is off.
  bool isEnabled(PushCategory category) {
    if (!master) return false;
    return switch (category) {
      PushCategory.jobRecommendations => jobRecommendations,
      PushCategory.applicationUpdates => applicationUpdates,
      PushCategory.interviewReminders => interviewReminders,
      PushCategory.employerNotifications => employerNotifications,
    };
  }

  PushPreferences copyWith({
    bool? master,
    bool? jobRecommendations,
    bool? applicationUpdates,
    bool? interviewReminders,
    bool? employerNotifications,
  }) =>
      PushPreferences(
        master: master ?? this.master,
        jobRecommendations: jobRecommendations ?? this.jobRecommendations,
        applicationUpdates: applicationUpdates ?? this.applicationUpdates,
        interviewReminders: interviewReminders ?? this.interviewReminders,
        employerNotifications:
            employerNotifications ?? this.employerNotifications,
      );

  Map<String, dynamic> toJson() => {
        'master': master,
        'jobRecommendations': jobRecommendations,
        'applicationUpdates': applicationUpdates,
        'interviewReminders': interviewReminders,
        'employerNotifications': employerNotifications,
      };

  factory PushPreferences.fromJson(Map<String, dynamic> json) => PushPreferences(
        master: _bool(json['master'], true),
        jobRecommendations:
            _bool(json['jobRecommendations'] ?? json['job_recommendations'], true),
        applicationUpdates:
            _bool(json['applicationUpdates'] ?? json['application_updates'], true),
        interviewReminders:
            _bool(json['interviewReminders'] ?? json['interview_reminders'], true),
        employerNotifications: _bool(
            json['employerNotifications'] ?? json['employer_notifications'], true),
      );

  @override
  List<Object?> get props => [
        master,
        jobRecommendations,
        applicationUpdates,
        interviewReminders,
        employerNotifications,
      ];
}

bool _bool(Object? v, bool fallback) => v is bool ? v : fallback;

/// Persistence seam for [PushPreferences].
///
/// In-memory today; rebind to a Firestore-backed implementation storing a
/// `pushPreferences` field on `users/{uid}` later — **no feature changes**, no
/// new Firestore rule (own-doc access already allowed).
abstract interface class PushPreferencesRepository {
  Stream<PushPreferences> watch(String uid);
  Future<PushPreferences> read(String uid);
  Future<void> save(String uid, PushPreferences prefs);
}

/// Session-scoped [PushPreferencesRepository] (default + tests).
class InMemoryPushPreferencesRepository implements PushPreferencesRepository {
  InMemoryPushPreferencesRepository({Map<String, PushPreferences>? seed})
      : _byUid = {...?seed};

  final Map<String, PushPreferences> _byUid;
  final Map<String, StreamController<PushPreferences>> _controllers = {};

  StreamController<PushPreferences> _controllerFor(String uid) =>
      _controllers.putIfAbsent(
          uid, () => StreamController<PushPreferences>.broadcast());

  @override
  Stream<PushPreferences> watch(String uid) async* {
    yield _byUid[uid] ?? PushPreferences.defaults;
    yield* _controllerFor(uid).stream;
  }

  @override
  Future<PushPreferences> read(String uid) async =>
      _byUid[uid] ?? PushPreferences.defaults;

  @override
  Future<void> save(String uid, PushPreferences prefs) async {
    _byUid[uid] = prefs;
    _controllerFor(uid).add(prefs);
  }
}

/// The app-wide push-preferences repository (swap for Firestore later).
final pushPreferencesRepositoryProvider = Provider<PushPreferencesRepository>(
  (ref) => InMemoryPushPreferencesRepository(),
);
