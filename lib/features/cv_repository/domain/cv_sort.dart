import '../../../core/services/cv_repository/cv_document.dart';

/// Sort orders for the CV library.
enum CvSortOption { updatedDesc, nameAsc, atsDesc, lastUsedDesc }

/// Applies a [CvSortOption] to a copy of [cvs] (stable, non-mutating).
List<CvDocument> sortCvs(List<CvDocument> cvs, CvSortOption option) {
  final out = [...cvs];
  switch (option) {
    case CvSortOption.updatedDesc:
      out.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    case CvSortOption.nameAsc:
      out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    case CvSortOption.atsDesc:
      out.sort((a, b) => (b.atsScore ?? -1).compareTo(a.atsScore ?? -1));
    case CvSortOption.lastUsedDesc:
      out.sort((a, b) => (b.lastUsedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.lastUsedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
  }
  return out;
}
