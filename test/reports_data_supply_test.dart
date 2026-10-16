import 'dart:async';

import 'package:dwell/features/cases/data/mock_cases.dart';
import 'package:dwell/features/cases/data/reports_cases_provider.dart';
import 'package:dwell/features/cases/models/case_filters.dart';
import 'package:dwell/features/cases/models/case_model.dart';
import 'package:dwell/features/cases/models/case_sort_order.dart';
import 'package:dwell/features/cases/models/reports_case_query.dart';
import 'package:dwell/features/cases/pages/cases_page.dart';
import 'package:dwell/features/cases/widgets/list/case_card.dart';
import 'package:dwell/features/cases/widgets/list/case_search_tabs.dart';
import 'package:dwell/features/cases/widgets/list/case_sort_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test(
    'Reports keeps prefix search, combined filters, status and sort semantics',
    () {
      final originalIds = mockCases.map((item) => item.id).toList();
      final filters = CaseFilters(
        selections: {
          CaseFilterGroup.issueType: {'Mold', 'Heating'},
          CaseFilterGroup.location: {'Bathroom'},
        },
      );
      final matching = matchingReportsCases(
        mockCases,
        search: '',
        filters: filters,
      );
      expect(matching.map((item) => item.id), ['mock-case-004']);
      final water = matchingReportsCases(
        mockCases,
        search: 'water',
        filters: CaseFilters(),
      );
      expect(
        visibleReportsCases(
          water,
          status: CaseStatus.logged,
          sort: CaseSortOrder.oldest,
        ).map((item) => item.id),
        ['mock-case-001', 'mock-case-003'],
      );
      expect(
        visibleReportsCases(
          water,
          status: CaseStatus.logged,
          sort: CaseSortOrder.newest,
        ).map((item) => item.id),
        ['mock-case-003', 'mock-case-001'],
      );
      expect(
        visibleReportsCases(
          water,
          status: CaseStatus.resolved,
          sort: CaseSortOrder.newest,
        ),
        isEmpty,
      );
      final title = mockCases.first.title;
      expect(
        matchingReportsCases(
          mockCases,
          search: ' ${title.substring(0, 5).toUpperCase()} ',
          filters: CaseFilters(),
        ),
        contains(mockCases.first),
      );
      expect(
        matchingReportsCases(
          mockCases,
          search: title.substring(2),
          filters: CaseFilters(),
        ),
        isNot(contains(mockCases.first)),
      );
      expect(mockCases.map((item) => item.id), originalIds);
    },
  );

  testWidgets(
    'Reports refresh keeps search, status, filters, sort and selection',
    (tester) async {
      final data = List<CaseModel>.of(mockCases.take(2));
      final container = ProviderContainer(
        overrides: [reportsCasesProvider.overrideWith((ref) => List.of(data))],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CasesPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Filter Cases'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Water Intrusion').last);
      await tester.pump();
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Water');
      tester
          .widget<CaseStatusTabs>(find.byType(CaseStatusTabs))
          .onChanged(CaseStatus.logged);
      tester
          .widget<CaseSortMenu>(find.byType(CaseSortMenu))
          .onChanged(CaseSortOrder.oldest);
      await tester.pumpAndSettle();
      final card = find.byType(CaseCard).first;
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pump();
      final selected = tester.widget<CaseCard>(card).caseItem.id;
      data.add(mockCases[2]);
      container.invalidate(reportsCasesProvider);
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<CaseCard>(find.byType(CaseCard))
            .map((card) => card.caseItem.id),
        ['mock-case-001', 'mock-case-003'],
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text ??
            tester
                .state<EditableTextState>(find.byType(EditableText))
                .widget
                .controller
                .text,
        'Water',
      );
      expect(
        tester
            .widget<CaseStatusTabs>(find.byType(CaseStatusTabs))
            .selectedStatus,
        CaseStatus.logged,
      );
      expect(
        tester.widget<CaseSortMenu>(find.byType(CaseSortMenu)).selectedOrder,
        CaseSortOrder.oldest,
      );
      expect(
        tester
            .widgetList<CaseCard>(find.byType(CaseCard))
            .where((item) => item.isSelected)
            .single
            .caseItem
            .id,
        selected,
      );
      expect(find.text('Water Intrusion'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Reports distinguishes loading, failure and empty refresh', (
    tester,
  ) async {
    var request = Completer<List<CaseModel>>();
    final container = ProviderContainer(
      overrides: [reportsCasesProvider.overrideWith((ref) => request.future)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CasesPage()),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    request.completeError(StateError('failure'));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load cases.'), findsOneWidget);
    request = Completer<List<CaseModel>>();
    await tester.tap(find.text('Retry'));
    await tester.pump();
    request.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('No cases found.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
