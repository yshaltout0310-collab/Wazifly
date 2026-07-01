import 'package:equatable/equatable.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/services/ai/ai_exception.dart';
import '../../../core/services/resume_store/resume_analysis_store.dart';
import '../data/resume_analyzer_repository_impl.dart';
import '../domain/resume_analysis.dart';
import '../domain/resume_analyzer_exception.dart';

/// Where the analyzer is in its lifecycle.
enum ResumeStatus { idle, analyzing, success, error }

/// UI-facing, localizable failure categories (unifies extraction + AI errors).
enum ResumeFailure {
  noText,
  extractionFailed,
  tooLarge,
  notConfigured,
  network,
  quota,
  invalidResponse,
  blocked,
  unknown,
}

/// Immutable state for the resume analyzer screen.
class ResumeAnalyzerState extends Equatable {
  const ResumeAnalyzerState({
    this.status = ResumeStatus.idle,
    this.analysis,
    this.fileName,
    this.failure,
  });

  final ResumeStatus status;
  final ResumeAnalysis? analysis;
  final String? fileName;
  final ResumeFailure? failure;

  bool get isBusy => status == ResumeStatus.analyzing;

  @override
  List<Object?> get props => [status, analysis, fileName, failure];
}

/// Drives the analyzer: pick a PDF → analyze → expose result / error.
class ResumeAnalyzerController extends StateNotifier<ResumeAnalyzerState> {
  ResumeAnalyzerController(this._ref) : super(const ResumeAnalyzerState());

  /// Test-only: start in a specific state so result/error views can be
  /// rendered without running the picker or AI.
  @visibleForTesting
  ResumeAnalyzerController.seeded(this._ref, ResumeAnalyzerState initial)
      : super(initial);

  final Ref _ref;

  /// Opens the file picker and, if a PDF is chosen, analyzes it.
  ///
  /// A cancelled pick leaves the current state untouched.
  Future<void> pickAndAnalyze() async {
    if (state.isBusy) return;

    final XFile? file;
    try {
      file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'PDF',
            extensions: ['pdf'],
            mimeTypes: ['application/pdf'],
            uniformTypeIdentifiers: ['com.adobe.pdf'],
          ),
        ],
      );
    } catch (e) {
      debugPrint('[ResumeAnalyzer] pick failed: $e');
      state = const ResumeAnalyzerState(
          status: ResumeStatus.error, failure: ResumeFailure.unknown);
      return;
    }

    if (file == null) return; // cancelled

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (e) {
      debugPrint('[ResumeAnalyzer] read failed: $e');
      state = const ResumeAnalyzerState(
          status: ResumeStatus.error, failure: ResumeFailure.extractionFailed);
      return;
    }
    await _analyze(bytes, file.name);
  }

  Future<void> _analyze(Uint8List bytes, String fileName) async {
    state = ResumeAnalyzerState(
        status: ResumeStatus.analyzing, fileName: fileName);
    try {
      final languageCode =
          _ref.read(localeControllerProvider)?.languageCode ?? 'en';
      final analysis = await _ref.read(resumeAnalyzerRepositoryProvider).analyze(
            pdfBytes: bytes,
            languageCode: languageCode,
            fileName: fileName,
          );
      // Cache the result so other features (e.g. Job Matching) can reuse it
      // without a re-upload. Persistence strategy lives behind the store.
      await _ref.read(lastResumeAnalysisProvider.notifier).set(analysis);
      if (!mounted) return;
      state = ResumeAnalyzerState(
        status: ResumeStatus.success,
        analysis: analysis,
        fileName: fileName,
      );
    } catch (e) {
      if (!mounted) return;
      state = ResumeAnalyzerState(
        status: ResumeStatus.error,
        fileName: fileName,
        failure: _mapFailure(e),
      );
    }
  }

  /// Clears the result and returns to the idle upload state.
  void reset() => state = const ResumeAnalyzerState();

  ResumeFailure _mapFailure(Object e) {
    if (e is ResumeAnalyzerException) {
      return switch (e.code) {
        ResumeErrorCode.noText => ResumeFailure.noText,
        ResumeErrorCode.tooLarge => ResumeFailure.tooLarge,
        ResumeErrorCode.extractionFailed => ResumeFailure.extractionFailed,
      };
    }
    if (e is AiException) {
      return switch (e.code) {
        AiErrorCode.notConfigured => ResumeFailure.notConfigured,
        AiErrorCode.network => ResumeFailure.network,
        AiErrorCode.quota => ResumeFailure.quota,
        AiErrorCode.emptyResponse ||
        AiErrorCode.invalidResponse =>
          ResumeFailure.invalidResponse,
        AiErrorCode.blocked => ResumeFailure.blocked,
        AiErrorCode.unknown => ResumeFailure.unknown,
      };
    }
    debugPrint('[ResumeAnalyzer] unmapped error: $e');
    return ResumeFailure.unknown;
  }
}

final resumeAnalyzerControllerProvider =
    StateNotifierProvider<ResumeAnalyzerController, ResumeAnalyzerState>(
  ResumeAnalyzerController.new,
);
