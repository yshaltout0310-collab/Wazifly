import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/jobs/employer_jobs_repository.dart';
import '../../../shared/models/job_posting.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/employment_type.dart';
import '../domain/job_experience.dart';
import '../domain/job_validation.dart';
import 'company_providers.dart';
import 'employer_jobs_providers.dart';

enum JobEditorFailure { notSignedIn, noCompany, saveFailed, unknown }

class JobEditorState extends Equatable {
  const JobEditorState({
    required this.draft,
    required this.isNew,
    this.savedSnapshot,
    this.dirty = false,
    this.saving = false,
    this.autosaving = false,
    this.lastSavedAt,
    this.showErrors = false,
    this.failure,
  });

  /// The working posting.
  final JobPosting draft;

  /// True until the draft has been persisted at least once.
  final bool isNew;

  /// The last persisted version (drives dirty compare + discard).
  final JobPosting? savedSnapshot;

  final bool dirty;
  final bool saving;
  final bool autosaving;
  final DateTime? lastSavedAt;

  /// Reveal inline validation errors (after a save/publish attempt).
  final bool showErrors;
  final JobEditorFailure? failure;

  bool get hasUnsavedChanges => dirty;

  JobEditorState copyWith({
    JobPosting? draft,
    bool? isNew,
    JobPosting? savedSnapshot,
    bool? dirty,
    bool? saving,
    bool? autosaving,
    DateTime? lastSavedAt,
    bool? showErrors,
    JobEditorFailure? failure,
    bool clearFailure = false,
  }) =>
      JobEditorState(
        draft: draft ?? this.draft,
        isNew: isNew ?? this.isNew,
        savedSnapshot: savedSnapshot ?? this.savedSnapshot,
        dirty: dirty ?? this.dirty,
        saving: saving ?? this.saving,
        autosaving: autosaving ?? this.autosaving,
        lastSavedAt: lastSavedAt ?? this.lastSavedAt,
        showErrors: showErrors ?? this.showErrors,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props =>
      [draft, isNew, savedSnapshot, dirty, saving, autosaving, lastSavedAt, showErrors, failure];
}

/// Drives the Create/Edit form: field mutations, two-tier validation, **draft
/// auto-save** (debounced), and dirty tracking for the unsaved-changes guard.
/// Persistence is repository-driven; publishing is handled by the lifecycle
/// controller after the preview confirmation.
class JobEditorController extends StateNotifier<JobEditorState> {
  JobEditorController(this._ref, String? jobId, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(_seed(_ref, jobId, clock ?? DateTime.now));

  /// Test-only: start from an explicit state.
  @visibleForTesting
  JobEditorController.seeded(this._ref, JobEditorState initial,
      {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(initial);

  final Ref _ref;
  final DateTime Function() _clock;
  Timer? _autosaveTimer;

  /// Debounce window for auto-save.
  static const Duration autosaveDelay = Duration(milliseconds: 2500);

  EmployerJobsRepository get _repo => _ref.read(employerJobsRepositoryProvider);

  static JobEditorState _seed(Ref ref, String? jobId, DateTime Function() clock) {
    if (jobId != null) {
      final existing = ref.read(employerJobByIdProvider(jobId));
      if (existing != null) {
        return JobEditorState(
            draft: existing, isNew: false, savedSnapshot: existing);
      }
    }
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final company = ref.read(currentCompanyProvider);
    final draft = JobPosting.create(
      id: 'job_${clock().microsecondsSinceEpoch}',
      companyId: company?.companyId ?? uid,
      ownerUid: uid,
      companyName: company?.name ?? '',
      now: clock(),
      by: uid,
    );
    return JobEditorState(draft: draft, isNew: true);
  }

  // --- field mutations ---

  void _mutate(JobPosting Function(JobPosting) f) {
    state = state.copyWith(draft: f(state.draft), dirty: true, clearFailure: true);
    _scheduleAutosave();
  }

  void setTitle(String v) => _mutate((d) => d.copyWith(title: v));
  void setDescription(String v) => _mutate((d) => d.copyWith(description: v));
  void setSkills(List<String> v) => _mutate((d) => d.copyWith(requiredSkills: v));
  void setLocation(String v) => _mutate((d) => d.copyWith(location: v));
  void setRemote(bool v) => _mutate((d) => d.copyWith(remote: v));
  void setExperience(JobExperience? v) =>
      _mutate((d) => d.copyWith(experience: v));
  void setEmploymentType(EmploymentType? v) =>
      _mutate((d) => d.copyWith(employmentType: v));
  void setOpenings(int? v) => _mutate((d) => d.copyWith(openings: v));
  void setSalary(SalaryRange? v) => _mutate((d) => d.copyWith(salary: v));
  void setOpensAt(DateTime? v) => _mutate((d) => d.copyWith(opensAt: v));
  void setExpiresAt(DateTime? v) => _mutate((d) => d.copyWith(expiresAt: v));

  // --- validation ---

  JobValidationResult get draftValidation => JobValidator.forDraft(state.draft);
  JobValidationResult get publishValidation =>
      JobValidator.forPublish(state.draft);

  void revealErrors() => state = state.copyWith(showErrors: true);

  // --- persistence ---

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(autosaveDelay, _autosave);
  }

  /// Silently persists the draft if it is dirty and minimally valid. Never
  /// publishes; never creates a near-empty document.
  Future<void> _autosave() async {
    if (!mounted || !state.dirty || state.saving) return;
    if (!draftValidation.isValid) return;
    state = state.copyWith(autosaving: true);
    final ok = await _persist();
    if (!mounted) return;
    state = state.copyWith(autosaving: false, dirty: !ok);
  }

  /// Manually saves the draft. Reveals errors + fails if the title is invalid.
  /// Returns the persisted posting, or null on failure.
  Future<JobPosting?> saveDraft() async {
    _autosaveTimer?.cancel();
    if (!draftValidation.isValid) {
      state = state.copyWith(showErrors: true);
      return null;
    }
    state = state.copyWith(saving: true, clearFailure: true);
    final ok = await _persist();
    state = state.copyWith(saving: false, dirty: !ok);
    return ok ? state.draft : null;
  }

  /// Shared create-or-update. Stamps audit + timestamps; flips `isNew` off after
  /// the first create. Returns true on success.
  Future<bool> _persist() async {
    final uid = _ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) {
      state = state.copyWith(failure: JobEditorFailure.notSignedIn);
      return false;
    }
    final now = _clock();
    final toSave = state.draft.copyWith(
      updatedAt: now,
      updatedBy: uid,
      createdAt: state.draft.createdAt ?? now,
      createdBy: state.draft.createdBy ?? uid,
    );
    try {
      if (state.isNew) {
        await _repo.createJob(toSave);
      } else {
        await _repo.updateJob(toSave);
      }
      state = state.copyWith(
        draft: toSave,
        isNew: false,
        savedSnapshot: toSave,
        lastSavedAt: now,
      );
      return true;
    } catch (e) {
      debugPrint('[JobEditor] save failed: $e');
      state = state.copyWith(failure: JobEditorFailure.saveFailed);
      return false;
    }
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    super.dispose();
  }
}

final jobEditorControllerProvider = StateNotifierProvider.autoDispose
    .family<JobEditorController, JobEditorState, String?>(
  (ref, jobId) => JobEditorController(ref, jobId),
);
