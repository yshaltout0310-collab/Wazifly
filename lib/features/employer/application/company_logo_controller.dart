import 'package:equatable/equatable.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/analytics/analytics_events.dart';
import '../../../core/services/analytics/firebase_analytics_service.dart';
import '../../../core/services/cloud_storage/storage_service.dart';
import '../../../core/services/company/company_logo_storage.dart';
import '../../../core/services/company/company_repository.dart';
import '../../../core/services/performance/firebase_performance_monitor.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/company_failure.dart';

enum LogoStatus { idle, working, error }

class CompanyLogoState extends Equatable {
  const CompanyLogoState({
    this.status = LogoStatus.idle,
    this.failure,
    this.progress = 0,
  });

  final LogoStatus status;
  final CompanyFailure? failure;

  /// Upload progress in `[0, 1]` while [status] is working.
  final double progress;

  bool get isWorking => status == LogoStatus.working;

  @override
  List<Object?> get props => [status, failure, progress];
}

/// Picks an image (via `file_selector` — no new plugin), uploads it through the
/// [CompanyLogoStorage] seam with progress, then persists the URL to the company
/// document. Also supports removing the logo. Mirrors `ProfilePhotoController`.
class CompanyLogoController extends StateNotifier<CompanyLogoState> {
  CompanyLogoController(this._ref) : super(const CompanyLogoState());

  final Ref _ref;

  Future<void> pickAndUpload() async {
    if (state.isWorking) return;

    final user = _ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      state = const CompanyLogoState(
          status: LogoStatus.error, failure: CompanyFailure.notSignedIn);
      return;
    }

    final XFile? file;
    try {
      file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Images',
            extensions: ['jpg', 'jpeg', 'png', 'webp'],
            mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
            uniformTypeIdentifiers: ['public.image'],
          ),
        ],
      );
    } catch (e) {
      debugPrint('[CompanyLogo] pick failed: $e');
      state = const CompanyLogoState(
          status: LogoStatus.error, failure: CompanyFailure.unknown);
      return;
    }

    if (file == null) return; // cancelled — leave state untouched

    final bytes = await file.readAsBytes();
    await uploadBytes(bytes, fileName: file.name);
  }

  /// Uploads [bytes] as the company logo (reporting progress) and persists the
  /// resulting URL. Split out from the picker so it is unit-testable without a
  /// platform file dialog.
  @visibleForTesting
  Future<void> uploadBytes(Uint8List bytes, {String fileName = 'logo.jpg'}) async {
    final user = _ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      state = const CompanyLogoState(
          status: LogoStatus.error, failure: CompanyFailure.notSignedIn);
      return;
    }

    state = const CompanyLogoState(status: LogoStatus.working);
    // Best-effort performance trace around the upload (never blocks/throws).
    final trace = _ref
        .read(performanceMonitorProvider)
        .newTrace(AnalyticsEvents.companyLogoUpload);
    await trace.start();
    try {
      final url = await _ref.read(companyLogoStorageProvider).uploadCompanyLogo(
            companyId: user.uid,
            bytes: bytes,
            contentType: _contentType(fileName),
            onProgress: _onProgress,
          );
      await trace.stop();
      if (url == null) {
        state = const CompanyLogoState(
            status: LogoStatus.error, failure: CompanyFailure.logoUploadFailed);
        return;
      }
      await _ref.read(companyRepositoryProvider).setLogoUrl(user.uid, url);
      _ref
          .read(analyticsServiceProvider)
          .logEvent(AnalyticsEvents.companyLogoUpload);
      state = const CompanyLogoState();
    } catch (e) {
      debugPrint('[CompanyLogo] upload failed: $e');
      state = const CompanyLogoState(
          status: LogoStatus.error, failure: CompanyFailure.logoUploadFailed);
    }
  }

  /// Removes the company logo from storage and clears the URL on the company
  /// document.
  Future<void> removeLogo() async {
    if (state.isWorking) return;
    final user = _ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      state = const CompanyLogoState(
          status: LogoStatus.error, failure: CompanyFailure.notSignedIn);
      return;
    }

    state = const CompanyLogoState(status: LogoStatus.working);
    try {
      await _ref.read(companyLogoStorageProvider).deleteCompanyLogo(user.uid);
      await _ref.read(companyRepositoryProvider).setLogoUrl(user.uid, '');
      state = const CompanyLogoState();
    } catch (e) {
      debugPrint('[CompanyLogo] remove failed: $e');
      state = const CompanyLogoState(
          status: LogoStatus.error, failure: CompanyFailure.logoUploadFailed);
    }
  }

  void _onProgress(StorageUploadProgress p) {
    if (!mounted) return;
    state = CompanyLogoState(status: LogoStatus.working, progress: p.fraction);
  }

  String _contentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

final companyLogoControllerProvider =
    StateNotifierProvider<CompanyLogoController, CompanyLogoState>(
  CompanyLogoController.new,
);
