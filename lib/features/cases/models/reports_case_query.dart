import 'case_filters.dart';
import 'case_model.dart';
import 'case_sort_order.dart';

/// Search and detailed filters determine tab counts, before the status filter.
List<CaseModel> matchingReportsCases(
  List<CaseModel> cases, {
  required String search,
  required CaseFilters filters,
}) {
  final query = search.trim().toLowerCase();
  return cases
      .where(
        (item) =>
            (query.isEmpty || item.title.toLowerCase().startsWith(query)) &&
            filters.matches(item),
      )
      .toList();
}

List<CaseModel> visibleReportsCases(
  List<CaseModel> matching, {
  required CaseStatus? status,
  required CaseSortOrder sort,
}) =>
    matching.where((item) => status == null || item.status == status).toList()
      ..sort((a, b) {
        final comparison = switch (sort) {
          CaseSortOrder.newest => b.createdAt.compareTo(a.createdAt),
          CaseSortOrder.oldest => a.createdAt.compareTo(b.createdAt),
        };
        return comparison != 0 ? comparison : a.id.compareTo(b.id);
      });
