import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/ai/ai_exception.dart';
import '../../../core/services/cv_repository/cv_repository.dart';
import '../../../core/services/resume_store/resume_analysis_store.dart';
import '../../auth/application/auth_providers.dart';
import '../../profile/application/profile_completion_provider.dart';
import '../data/cv_enhancement_repository_impl.dart';
import '../domain/cv_builder_exception.dart';
import '../domain/cv_data.dart';
import '../domain/cv_template.dart';
import '../../../core/services/cv_store/cv_draft_store.dart';

enum CvBuilderStatus { needsProfile, editing, enhancing }

/// UI-facing failure categories for the AI enhancement step.
enum CvBuilderFailure {
  notConfigured,
  network,
  quota,
  invalidResponse,
  emptyEnhancement,
  unknown,
}

class CvBuilderState extends Equatable {
  const CvBuilderState({
    this.status = CvBuilderStatus.editing,
    this.data = const CvData(),
    this.templateId = kDefaultCvTemplate,
    this.failure,
  });

  final CvBuilderStatus status;
  final CvData data;
  final CvTemplateId templateId;
  final CvBuilderFailure? failure;

  bool get isEnhancing => status == CvBuilderStatus.enhancing;
  bool get canExport => !data.isEmpty && status != CvBuilderStatus.needsProfile;

  CvBuilderState copyWith({
    CvBuilderStatus? status,
    CvData? data,
    CvTemplateId? templateId,
    CvBuilderFailure? failure,
    bool clearFailure = false,
  }) =>
      CvBuilderState(
        status: status ?? this.status,
        data: data ?? this.data,
        templateId: templateId ?? this.templateId,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [status, data, templateId, failure];
}

/// Drives the CV Builder: seed from profile (+ resume analysis) → edit →
/// enhance with AI → (preview/export handled by the preview screen).
class CvBuilderController extends StateNotifier<CvBuilderState> {
  CvBuilderController(this._ref) : super(const CvBuilderState()) {
    _init();
  }

  /// Test-only: start in an explicit state.
  @visibleForTesting
  CvBuilderController.seeded(this._ref, CvBuilderState initial) : super(initial);

  final Ref _ref;

  /// When set, the Builder is editing a specific stored CV and can save back to
  /// it (via [saveToRepository]). Null = the ad-hoc single-draft mode (unchanged
  /// legacy behavior).
  String? editingCvId;

  /// Begins editing a stored CV's [content] (from the CV repository).
  void beginEditing(String cvId, CvData content) {
    editingCvId = cvId;
    _ref.read(cvDraftStoreProvider).write(content);
    state = state.copyWith(
        status: CvBuilderStatus.editing, data: content, clearFailure: true);
  }

  /// Leaves CV-editing mode (back to the ad-hoc draft).
  void stopEditing() => editingCvId = null;

  /// Persists the current content back onto the stored CV (bumping its version).
  /// Returns false if not editing a stored CV.
  Future<bool> saveToRepository() async {
    final id = editingCvId;
    if (id == null) return false;
    final cv = _ref.read(cvByIdProvider(id));
    if (cv == null) return false;
    await _ref
        .read(cvRepositoryProvider)
        .updateCv(cv.withContent(state.data, DateTime.now()));
    return true;
  }

  void _init() {
    final user = _ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      state = const CvBuilderState(status: CvBuilderStatus.needsProfile);
      return;
    }
    // Resume an in-progress draft if one exists this session…
    final draft = _ref.read(cvDraftStoreProvider).read();
    if (draft != null) {
      state = CvBuilderState(status: CvBuilderStatus.editing, data: draft);
      return;
    }
    // …otherwise seed from the profile + cached resume analysis.
    state = CvBuilderState(status: CvBuilderStatus.editing, data: _seed());
  }

  CvData _seed() {
    final profile = _ref.read(currentUserProfileProvider);
    final user = _ref.read(authRepositoryProvider).currentUser;
    final analysis = _ref.read(lastResumeAnalysisProvider);
    if (profile == null) return const CvData();
    return CvData.fromProfile(profile, user: user, analysis: analysis);
  }

  /// Replaces the working CV (called by the edit form) and mirrors it into the
  /// draft store so edits survive navigation.
  void updateData(CvData data) {
    _ref.read(cvDraftStoreProvider).write(data);
    state = state.copyWith(data: data, clearFailure: true);
  }

  void selectTemplate(CvTemplateId id) =>
      state = state.copyWith(templateId: id);

  /// Re-seeds the form from the profile + resume analysis, discarding edits.
  void resetFromProfile() {
    final data = _seed();
    _ref.read(cvDraftStoreProvider).write(data);
    state = state.copyWith(data: data, clearFailure: true);
  }

  void clearFailure() => state = state.copyWith(clearFailure: true);

  /// Runs the AI enhancement, reusing the cached resume analysis when present.
  Future<void> enhance({required String languageCode}) async {
    if (state.isEnhancing) return;
    state = state.copyWith(status: CvBuilderStatus.enhancing, clearFailure: true);
    try {
      final enhanced = await _ref
          .read(cvEnhancementRepositoryProvider)
          .enhance(
            state.data,
            languageCode: languageCode,
            analysis: _ref.read(lastResumeAnalysisProvider),
          );
      _ref.read(cvDraftStoreProvider).write(enhanced);
      state = state.copyWith(
          status: CvBuilderStatus.editing, data: enhanced, clearFailure: true);
    } catch (e) {
      debugPrint('[CvBuilder] enhance failed: $e');
      state = state.copyWith(
          status: CvBuilderStatus.editing, failure: _mapFailure(e));
    }
  }

  CvBuilderFailure _mapFailure(Object e) {
    if (e is CvBuilderException &&
        e.code == CvErrorCode.emptyEnhancement) {
      return CvBuilderFailure.emptyEnhancement;
    }
    if (e is AiException) {
      return switch (e.code) {
        AiErrorCode.notConfigured => CvBuilderFailure.notConfigured,
        AiErrorCode.network => CvBuilderFailure.network,
        AiErrorCode.quota => CvBuilderFailure.quota,
        AiErrorCode.emptyResponse ||
        AiErrorCode.invalidResponse =>
          CvBuilderFailure.invalidResponse,
        _ => CvBuilderFailure.unknown,
      };
    }
    return CvBuilderFailure.unknown;
  }
}

final cvBuilderControllerProvider =
    StateNotifierProvider<CvBuilderController, CvBuilderState>(
  CvBuilderController.new,
);
