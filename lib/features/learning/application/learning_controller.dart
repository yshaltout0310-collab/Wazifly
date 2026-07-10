import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/learning/learning_profile_repository.dart';
import '../../../shared/models/learning_profile.dart';
import '../../auth/application/auth_providers.dart';

/// Why a learning-interest action failed (mapped to a localized message).
enum LearningFailure { notSignedIn, saveFailed }

/// UI/action state for the Learning Interests screen. The interest data itself
/// comes from the reactive [learningProfileProvider]; this holds only the search
/// query + transient action status.
class LearningState extends Equatable {
  const LearningState({this.query = '', this.saving = false, this.failure});

  final String query;
  final bool saving;
  final LearningFailure? failure;

  LearningState copyWith({
    String? query,
    bool? saving,
    LearningFailure? failure,
    bool clearFailure = false,
  }) =>
      LearningState(
        query: query ?? this.query,
        saving: saving ?? this.saving,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [query, saving, failure];
}

/// Owns learning-interest actions (add / edit / delete / search). Reads the
/// current profile from the core [learningProfileProvider], applies a **pure**
/// [LearningProfile] transition, then persists via [LearningProfileRepository];
/// the reactive stream re-renders. Save failures roll back to the last persisted
/// profile implicitly (the stream never advanced) and surface a failure.
class LearningController extends StateNotifier<LearningState> {
  LearningController(this._ref) : super(const LearningState());

  /// Test-only: start from an explicit state.
  @visibleForTesting
  LearningController.seeded(this._ref, LearningState initial) : super(initial);

  final Ref _ref;

  LearningProfileRepository get _repo =>
      _ref.read(learningProfileRepositoryProvider);
  String? get _uid => _ref.read(authRepositoryProvider).currentUser?.uid;
  DateTime _now() => DateTime.now();

  LearningProfile get _current {
    final uid = _uid ?? '';
    return _ref.read(learningProfileProvider).valueOrNull ??
        LearningProfile.empty(uid);
  }

  void setSearch(String text) => state = state.copyWith(query: text);

  void clearFailure() => state = state.copyWith(clearFailure: true);

  /// Adds a new interest to [category]. Idempotent by (category, label).
  Future<bool> addInterest({
    required LearningCategory category,
    required String label,
    String? note,
  }) async {
    if (label.trim().isEmpty) return false;
    final interest = LearningInterest.create(
      category: category,
      label: label,
      now: _now(),
      note: note,
    );
    return _save(_current.added(interest, _now()));
  }

  /// Replaces [existing] with an edited label/note (id may change with the label).
  Future<bool> editInterest(
    LearningInterest existing, {
    required String label,
    String? note,
  }) async {
    if (label.trim().isEmpty) return false;
    final updated = existing.copyWith(
      label: label,
      note: note,
      clearNote: note == null || note.trim().isEmpty,
    );
    return _save(_current.edited(existing.id, updated, _now()));
  }

  Future<bool> deleteInterest(LearningInterest interest) async =>
      _save(_current.removed(interest.id, _now()));

  Future<bool> _save(LearningProfile next) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      state = state.copyWith(failure: LearningFailure.notSignedIn);
      return false;
    }
    state = state.copyWith(saving: true, clearFailure: true);
    try {
      await _repo.saveProfile(next.copyWithUid(uid));
      state = state.copyWith(saving: false);
      return true;
    } catch (e) {
      debugPrint('[Learning] save failed: $e');
      state = state.copyWith(saving: false, failure: LearningFailure.saveFailed);
      return false;
    }
  }
}

/// Small extension so [_save] can guarantee the persisted profile carries the
/// signed-in uid even if the reactive profile was the empty (uid-less) default.
extension on LearningProfile {
  LearningProfile copyWithUid(String uid) =>
      uid == this.uid ? this : LearningProfile(uid: uid, interests: interests, updatedAt: updatedAt);
}

final learningControllerProvider =
    StateNotifierProvider<LearningController, LearningState>(
  LearningController.new,
);
