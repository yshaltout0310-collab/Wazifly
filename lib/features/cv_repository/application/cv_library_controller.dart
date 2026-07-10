import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/cv_repository/cv_document.dart';
import '../../../core/services/cv_repository/cv_repository.dart';
import '../domain/cv_sort.dart';

/// Which CVs the library shows.
enum CvStatusFilter { active, archived }

class CvLibraryState extends Equatable {
  const CvLibraryState({
    this.query = '',
    this.sort = CvSortOption.updatedDesc,
    this.filter = CvStatusFilter.active,
  });

  final String query;
  final CvSortOption sort;
  final CvStatusFilter filter;

  CvLibraryState copyWith({
    String? query,
    CvSortOption? sort,
    CvStatusFilter? filter,
  }) =>
      CvLibraryState(
        query: query ?? this.query,
        sort: sort ?? this.sort,
        filter: filter ?? this.filter,
      );

  @override
  List<Object?> get props => [query, sort, filter];
}

/// Holds the CV library's search / sort / status-filter state.
class CvLibraryController extends StateNotifier<CvLibraryState> {
  CvLibraryController() : super(const CvLibraryState());

  void setQuery(String q) => state = state.copyWith(query: q);
  void setSort(CvSortOption s) => state = state.copyWith(sort: s);
  void setFilter(CvStatusFilter f) => state = state.copyWith(filter: f);
}

final cvLibraryControllerProvider =
    StateNotifierProvider<CvLibraryController, CvLibraryState>(
  (ref) => CvLibraryController(),
);

/// The CVs to display: filtered by status + search (matching **name and tags**
/// and the target role), then sorted. Soft-deleted CVs are already excluded by
/// the repository stream.
final visibleCvsProvider = Provider<List<CvDocument>>((ref) {
  final all = ref.watch(cvDocumentsProvider).valueOrNull ?? const [];
  final s = ref.watch(cvLibraryControllerProvider);

  Iterable<CvDocument> list = all.where(
    (c) => s.filter == CvStatusFilter.active ? c.isActive : c.isArchived,
  );

  final q = s.query.trim().toLowerCase();
  if (q.isNotEmpty) {
    list = list.where((c) =>
        c.name.toLowerCase().contains(q) ||
        c.tags.any((t) => t.toLowerCase().contains(q)) ||
        c.content.targetRole.toLowerCase().contains(q));
  }

  return sortCvs(list.toList(), s.sort);
});
