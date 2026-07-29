import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/services/ai/ai_exception.dart';
import '../../../core/services/applications/employer_applicants_repository.dart';
import '../data/candidate_match_repository_impl.dart';
import '../domain/candidate_match.dart';

/// The employer's applicant pool flattened + de-duplicated into primitive
/// [CandidateProfile]s (one entry per person, richest snapshot wins). Reused by
/// the screen (to show/hide the empty state) and the controller (to rank).
final employerCandidatePoolProvider = Provider<List<CandidateProfile>>((ref) {
  final apps = ref.watch(employerApplicantsProvider).valueOrNull ?? const [];
  final byKey = <String, CandidateProfile>{};
  for (final a in apps) {
    final snap = a.applicant;
    if (snap == null || snap.name.trim().isEmpty) continue;
    final key = a.applicantUid.isNotEmpty ? a.applicantUid : snap.name.trim();
    final profile = CandidateProfile(
      id: key,
      name: snap.name.trim(),
      headline: snap.headline ?? '',
      location: snap.location ?? '',
      experienceLevel: snap.experienceLevel ?? '',
      skills: snap.skills,
      resumeSummary: snap.resumeSummary ?? '',
      atsScore: snap.atsScore,
    );
    final existing = byKey[key];
    // Keep the richer snapshot (more skills) when the same person applied twice.
    if (existing == null || profile.skills.length > existing.skills.length) {
      byKey[key] = profile;
    }
  }
  return List.unmodifiable(byKey.values);
});

enum CandidateMatchPhase { idle, loading, ready, error }

enum CandidateMatchFailure {
  notConfigured,
  network,
  quota,
  invalidResponse,
  empty,
  unknown,
}

class CandidateMatchState extends Equatable {
  const CandidateMatchState({
    this.phase = CandidateMatchPhase.idle,
    this.shortlist,
    this.failure,
  });

  final CandidateMatchPhase phase;
  final CandidateShortlist? shortlist;
  final CandidateMatchFailure? failure;

  bool get isLoading => phase == CandidateMatchPhase.loading;

  CandidateMatchState copyWith({
    CandidateMatchPhase? phase,
    CandidateShortlist? shortlist,
    CandidateMatchFailure? failure,
    bool clearFailure = false,
  }) =>
      CandidateMatchState(
        phase: phase ?? this.phase,
        shortlist: shortlist ?? this.shortlist,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [phase, shortlist, failure];
}

/// Drives the AI candidate-matching tool: pulls the current applicant pool,
/// ranks it against the target role via the repository, and maps failures.
class CandidateMatchController extends StateNotifier<CandidateMatchState> {
  CandidateMatchController(this._ref) : super(const CandidateMatchState());

  final Ref _ref;

  String get _languageCode =>
      _ref.read(localeControllerProvider)?.languageCode ?? 'en';

  Future<void> generate(String role) async {
    final pool = _ref.read(employerCandidatePoolProvider);
    if (pool.isEmpty) return; // the screen guards this; nothing to rank.

    state = state.copyWith(
        phase: CandidateMatchPhase.loading, clearFailure: true);
    try {
      final shortlist = await _ref
          .read(candidateMatchRepositoryProvider)
          .rank(role: role.trim(), candidates: pool, languageCode: _languageCode);
      if (!mounted) return;
      state =
          CandidateMatchState(phase: CandidateMatchPhase.ready, shortlist: shortlist);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
          phase: CandidateMatchPhase.error, failure: _mapFailure(e));
    }
  }

  CandidateMatchFailure _mapFailure(Object e) {
    if (e is CandidateMatchException) return CandidateMatchFailure.empty;
    if (e is AiException) {
      return switch (e.code) {
        AiErrorCode.notConfigured => CandidateMatchFailure.notConfigured,
        AiErrorCode.network => CandidateMatchFailure.network,
        AiErrorCode.quota => CandidateMatchFailure.quota,
        AiErrorCode.emptyResponse ||
        AiErrorCode.invalidResponse =>
          CandidateMatchFailure.invalidResponse,
        _ => CandidateMatchFailure.unknown,
      };
    }
    debugPrint('[CandidateMatch] failed: $e');
    return CandidateMatchFailure.unknown;
  }
}

final candidateMatchControllerProvider =
    StateNotifierProvider<CandidateMatchController, CandidateMatchState>(
  CandidateMatchController.new,
);
