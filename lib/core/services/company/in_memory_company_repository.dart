import 'dart:async';

import '../../../shared/models/company.dart';
import 'company_repository.dart';

/// Session-scoped [CompanyRepository] for tests and offline runs.
///
/// Holds one company per id in memory and re-emits the current value on every
/// change through a per-id broadcast stream (mirroring Firestore `.snapshots()`).
class InMemoryCompanyRepository implements CompanyRepository {
  InMemoryCompanyRepository({List<Company> seed = const []}) {
    for (final c in seed) {
      _companies[c.companyId] = c;
    }
  }

  final Map<String, Company> _companies = {};
  final Map<String, StreamController<Company?>> _controllers = {};

  StreamController<Company?> _controllerFor(String id) =>
      _controllers.putIfAbsent(
        id,
        () => StreamController<Company?>.broadcast(),
      );

  void _emit(String id) => _controllerFor(id).add(_companies[id]);

  @override
  Stream<Company?> watchCompany(String companyId) async* {
    yield _companies[companyId]; // current value to new listeners
    yield* _controllerFor(companyId).stream;
  }

  @override
  Future<Company?> fetchCompany(String companyId) async =>
      _companies[companyId];

  @override
  Future<void> saveCompany(Company company) async {
    _companies[company.companyId] = company;
    _emit(company.companyId);
  }

  @override
  Future<void> ensureCompany(String ownerUid,
      {String? email, String? name}) async {
    final existing = _companies[ownerUid];
    if (existing != null) return; // idempotent — don't clobber edits
    _companies[ownerUid] = Company.empty(ownerUid).copyWith(
      contactEmail: email,
      name: name,
    );
    _emit(ownerUid);
  }

  @override
  Future<void> setLogoUrl(String companyId, String url) async {
    final base = _companies[companyId] ?? Company.empty(companyId);
    _companies[companyId] = base.copyWith(logoUrl: url);
    _emit(companyId);
  }
}
