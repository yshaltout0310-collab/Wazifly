import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/company/company_repository.dart';
import '../../../shared/models/company.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/company_failure.dart';

enum CompanyEditStatus { idle, saving, success, error }

class CompanyEditState extends Equatable {
  const CompanyEditState({this.status = CompanyEditStatus.idle, this.failure});

  final CompanyEditStatus status;
  final CompanyFailure? failure;

  bool get isSaving => status == CompanyEditStatus.saving;

  @override
  List<Object?> get props => [status, failure];
}

/// Saves edits to the company document. Backend-agnostic — depends only on the
/// [CompanyRepository] + auth interfaces. Auto-derives [Company.companySlug] from
/// the name on save when it's empty (so a future public company URL needs no
/// migration).
class CompanyEditController extends StateNotifier<CompanyEditState> {
  CompanyEditController(this._ref) : super(const CompanyEditState());

  final Ref _ref;

  /// Persists [edited] for the signed-in employer. Returns true on success.
  Future<bool> save(Company edited) async {
    final user = _ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      state = const CompanyEditState(
          status: CompanyEditStatus.error, failure: CompanyFailure.notSignedIn);
      return false;
    }

    state = const CompanyEditState(status: CompanyEditStatus.saving);
    try {
      var company = edited.copyWith(companyId: user.uid, ownerUid: user.uid);
      // Seed the URL-safe slug from the name once, when not already set.
      final name = company.name?.trim() ?? '';
      if ((company.companySlug == null || company.companySlug!.isEmpty) &&
          name.isNotEmpty) {
        company = company.copyWith(companySlug: Company.slugify(name));
      }
      await _ref.read(companyRepositoryProvider).saveCompany(company);
      state = const CompanyEditState(status: CompanyEditStatus.success);
      return true;
    } catch (e) {
      debugPrint('[CompanyEdit] save failed: $e');
      state = const CompanyEditState(
          status: CompanyEditStatus.error, failure: CompanyFailure.saveFailed);
      return false;
    }
  }
}

final companyEditControllerProvider =
    StateNotifierProvider<CompanyEditController, CompanyEditState>(
  CompanyEditController.new,
);
