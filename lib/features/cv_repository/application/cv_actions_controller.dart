import 'package:equatable/equatable.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/services/ai/ai_exception.dart';
import '../../../core/services/cv_repository/cv_document.dart';
import '../../../core/services/cv_repository/cv_repository.dart';
import '../../../core/services/user_profile/user_profile_repository.dart';
import '../../auth/application/auth_providers.dart';
import '../../cv_builder/domain/cv_data.dart';
import '../../resume_analyzer/data/resume_analyzer_repository_impl.dart';
import '../../resume_analyzer/domain/resume_analysis.dart';
import '../../resume_analyzer/domain/resume_analyzer_exception.dart';
import '../domain/cv_repository_failure.dart';

/// A prepared, analyzed import awaiting the user's dedup decision.
class PendingImport {
  const PendingImport({
    required this.name,
    required this.content,
    required this.analysis,
    required this.importHash,
  });

  final String name;
  final CvData content;
  final ResumeAnalysis analysis;
  final String importHash;
}

/// The outcome of an import attempt.
enum ImportKind { created, duplicate, cancelled, failed }

typedef ImportOutcome = ({
  ImportKind kind,
  CvDocument? created,
  CvDocument? existing,
  PendingImport? pending,
  CvActionFailure? failure,
});

class CvActionsState extends Equatable {
  const CvActionsState({this.importing = false, this.failure});

  final bool importing;
  final CvActionFailure? failure;

  CvActionsState copyWith({
    bool? importing,
    CvActionFailure? failure,
    bool clearFailure = false,
  }) =>
      CvActionsState(
        importing: importing ?? this.importing,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [importing, failure];
}

/// Owns CV lifecycle actions (create / import / rename / duplicate / archive /
/// restore / set-default / delete). Enforces the invariants:
///  • the user always keeps ≥ 1 active CV (delete/archive of the last is blocked),
///  • the first CV becomes the default automatically,
///  • removing the default auto-promotes another active CV.
/// Persists through the core [CvRepository]; the reactive stream re-renders the UI.
class CvActionsController extends StateNotifier<CvActionsState> {
  CvActionsController(this._ref) : super(const CvActionsState());

  final Ref _ref;

  CvRepository get _repo => _ref.read(cvRepositoryProvider);
  String? get _uid => _ref.read(authRepositoryProvider).currentUser?.uid;
  DateTime _now() => DateTime.now();
  String _newId() =>
      'cv_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  List<CvDocument> get _activeCvs => _ref.read(activeCvsProvider);

  void clearFailure() => state = state.copyWith(clearFailure: true);

  /// Seeds CV content from the user's profile + auth contact (+ optional AI
  /// summary), tolerating a missing profile.
  CvData _seed({String? summary}) {
    final profile = _ref.read(userProfileProvider).valueOrNull;
    final user = _ref.read(authRepositoryProvider).currentUser;
    final base = profile != null
        ? CvData.fromProfile(profile, user: user)
        : CvData(
            fullName: (user?.displayName ?? '').trim(),
            email: (user?.email ?? '').trim(),
            phone: (user?.phoneNumber ?? '').trim(),
          );
    if (summary != null && summary.trim().isNotEmpty) {
      return base.copyWith(summary: summary.trim());
    }
    return base;
  }

  // --- Create ---------------------------------------------------------------

  /// Creates a blank CV seeded from the profile. The first CV is auto-default.
  Future<CvDocument?> createFromProfile({required String name}) async {
    final uid = _uid;
    if (uid == null) return null;
    final doc = CvDocument.create(
      id: _newId(),
      ownerUid: uid,
      name: name.trim().isEmpty ? 'Untitled CV' : name.trim(),
      content: _seed(),
      now: _now(),
      isDefault: _activeCvs.isEmpty,
    );
    return _repo.createCv(doc);
  }

  // --- Import (with dedup) --------------------------------------------------

  /// Picks a PDF, analyzes it (reusing the resume-analysis pipeline), and either
  /// creates a CV or — if an identical file was already imported — returns a
  /// [ImportKind.duplicate] outcome for the UI to resolve.
  Future<ImportOutcome> pickAndImport() async {
    if (_uid == null) return _failed(CvActionFailure.unknown);

    final XFile? file;
    try {
      file = await openFile(acceptedTypeGroups: const [
        XTypeGroup(
          label: 'PDF',
          extensions: ['pdf'],
          mimeTypes: ['application/pdf'],
          uniformTypeIdentifiers: ['com.adobe.pdf'],
        ),
      ]);
    } catch (e) {
      debugPrint('[CvRepository] import pick failed: $e');
      return _failed(CvActionFailure.importFailed);
    }
    if (file == null) {
      return _cancelled();
    }

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (e) {
      debugPrint('[CvRepository] import read failed: $e');
      return _failed(CvActionFailure.importFailed);
    }

    state = state.copyWith(importing: true, clearFailure: true);
    try {
      final languageCode =
          _ref.read(localeControllerProvider)?.languageCode ?? 'en';
      final analysis = await _ref.read(resumeAnalyzerRepositoryProvider).analyze(
            pdfBytes: bytes,
            languageCode: languageCode,
            fileName: file.name,
          );
      final importHash = CvDocument.hashBytes(bytes);
      final pending = PendingImport(
        name: _importName(file.name),
        content: _seed(summary: analysis.summary),
        analysis: analysis,
        importHash: importHash,
      );

      // Dedup: an identical source already imported (active)?
      CvDocument? duplicate;
      for (final c in _activeCvs) {
        if (c.importHash != null && c.importHash == importHash) {
          duplicate = c;
          break;
        }
      }

      state = state.copyWith(importing: false);
      if (duplicate != null) {
        return (
          kind: ImportKind.duplicate,
          created: null,
          existing: duplicate,
          pending: pending,
          failure: null,
        );
      }
      final created = await confirmImportAsNew(pending);
      return (
        kind: ImportKind.created,
        created: created,
        existing: null,
        pending: null,
        failure: null,
      );
    } catch (e) {
      state = state.copyWith(importing: false);
      return _failed(_mapImportFailure(e));
    }
  }

  /// Creates a new CV from a prepared import (first CV auto-default).
  Future<CvDocument?> confirmImportAsNew(PendingImport pending) async {
    final uid = _uid;
    if (uid == null) return null;
    final doc = CvDocument.create(
      id: _newId(),
      ownerUid: uid,
      name: pending.name,
      content: pending.content,
      now: _now(),
      source: CvSource.imported,
      isDefault: _activeCvs.isEmpty,
      analysis: pending.analysis,
      importHash: pending.importHash,
    );
    return _repo.createCv(doc);
  }

  /// Replaces an existing CV's content + analysis with a prepared import
  /// (bumps the version), keeping its name / default / metadata.
  Future<void> confirmImportReplace(
    CvDocument existing,
    PendingImport pending,
  ) async {
    final now = _now();
    final updated = existing
        .withContent(pending.content, now)
        .withAnalysis(pending.analysis, now)
        .copyWith(importHash: pending.importHash, source: CvSource.imported);
    await _repo.updateCv(updated);
  }

  // --- Metadata / lifecycle -------------------------------------------------

  Future<void> rename(CvDocument cv, String name) =>
      _repo.updateCv(cv.renamed(name, _now()));

  Future<void> updateTags(CvDocument cv, List<String> tags) =>
      _repo.updateCv(cv.withTags(tags, _now()));

  Future<CvDocument?> duplicate(CvDocument cv, {required String copyLabel}) {
    final dup = cv.duplicatedAs(
      id: _newId(),
      name: '${cv.name} $copyLabel',
      now: _now(),
    );
    return _repo.createCv(dup);
  }

  Future<void> setDefault(CvDocument cv) async {
    final uid = _uid;
    if (uid == null) return;
    await _repo.setDefault(uid, cv.id);
  }

  /// Archives [cv]. Blocked (returns false) if it's the last active CV.
  Future<bool> archive(CvDocument cv) async {
    if (!_canRemove(cv)) {
      state = state.copyWith(failure: CvActionFailure.lastActiveCv);
      return false;
    }
    await _repo.updateCv(cv.archived(_now()));
    await _promoteDefaultIfNeeded(cv);
    return true;
  }

  Future<void> restore(CvDocument cv) async {
    await _repo.updateCv(cv.restored(_now()));
    // If nothing is default among actives, make the restored one default.
    if (_ref.read(defaultCvProvider) == null) {
      await setDefault(cv);
    }
  }

  /// Soft-deletes [cv]. Blocked (returns false) if it's the last active CV.
  Future<bool> delete(CvDocument cv) async {
    if (!_canRemove(cv)) {
      state = state.copyWith(failure: CvActionFailure.lastActiveCv);
      return false;
    }
    await _repo.updateCv(cv.softDeleted(_now()));
    await _promoteDefaultIfNeeded(cv);
    return true;
  }

  // --- Helpers --------------------------------------------------------------

  /// The user must always keep ≥ 1 active CV.
  bool _canRemove(CvDocument cv) {
    if (!cv.isActive) return true; // archived/deleted don't reduce the active set
    return _activeCvs.where((c) => c.id != cv.id).isNotEmpty;
  }

  /// If [removed] was the default, promote the newest remaining active CV.
  Future<void> _promoteDefaultIfNeeded(CvDocument removed) async {
    if (!removed.isDefault) return;
    final remaining = _activeCvs.where((c) => c.id != removed.id).toList();
    if (remaining.isEmpty) return;
    await setDefault(remaining.first); // activeCvs is newest-updated first
  }

  String _importName(String fileName) {
    var n = fileName.trim();
    final dot = n.lastIndexOf('.');
    if (dot > 0) n = n.substring(0, dot);
    n = n.replaceAll('_', ' ').trim();
    return n.isEmpty ? 'Imported CV' : n;
  }

  ImportOutcome _cancelled() => (
        kind: ImportKind.cancelled,
        created: null,
        existing: null,
        pending: null,
        failure: null,
      );

  ImportOutcome _failed(CvActionFailure f) {
    state = state.copyWith(failure: f, importing: false);
    return (
      kind: ImportKind.failed,
      created: null,
      existing: null,
      pending: null,
      failure: f,
    );
  }

  CvActionFailure _mapImportFailure(Object e) {
    if (e is ResumeAnalyzerException) {
      return switch (e.code) {
        ResumeErrorCode.noText => CvActionFailure.importNoText,
        _ => CvActionFailure.importFailed,
      };
    }
    if (e is AiException) {
      return switch (e.code) {
        AiErrorCode.notConfigured => CvActionFailure.notConfigured,
        AiErrorCode.network => CvActionFailure.network,
        AiErrorCode.quota => CvActionFailure.quota,
        AiErrorCode.emptyResponse ||
        AiErrorCode.invalidResponse =>
          CvActionFailure.invalidResponse,
        _ => CvActionFailure.unknown,
      };
    }
    return CvActionFailure.unknown;
  }
}

final cvActionsControllerProvider =
    StateNotifierProvider<CvActionsController, CvActionsState>(
  CvActionsController.new,
);
