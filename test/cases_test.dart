import 'package:dwell/features/cases/data/mock_cases.dart';
import 'package:dwell/features/cases/models/case_filters.dart';
import 'package:dwell/features/cases/models/case_model.dart';
import 'package:dwell/features/cases/models/case_sort_order.dart';
import 'package:dwell/features/cases/pages/cases_page.dart';
import 'package:dwell/features/cases/widgets/list/case_card.dart';
import 'package:dwell/features/cases/widgets/list/case_search_tabs.dart';
import 'package:dwell/features/cases/widgets/list/case_sort_menu.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Every mock filter value belongs to the design options', () {
    for (final item in mockCases) {
      final values = <CaseFilterGroup, String>{
        CaseFilterGroup.severity: switch (item.severity) {
          CaseSeverity.high => 'High',
          CaseSeverity.medium => 'Medium',
          CaseSeverity.low => 'Low',
        },
        CaseFilterGroup.issueType: item.issueType,
        CaseFilterGroup.location: item.location,
        CaseFilterGroup.affectedArea: item.affectedArea,
        CaseFilterGroup.visibility: item.isPublic ? 'Public' : 'Private',
      };
      for (final entry in values.entries) {
        expect(CaseFilterOptions.values[entry.key], contains(entry.value));
      }
    }
    for (final group in CaseFilterGroup.values) {
      for (final value in CaseFilterOptions.values[group]!) {
        final filter = CaseFilters(
          selections: {
            group: {value},
          },
        );
        expect(mockCases.where(filter.matches), isNotEmpty, reason: value);
      }
    }
  });

  test('Filters retain OR within a group and AND across groups', () {
    final filters = CaseFilters(
      selections: {
        CaseFilterGroup.issueType: {'Mold', 'Heating'},
        CaseFilterGroup.location: {'Bathroom'},
      },
    );
    expect(mockCases.where(filters.matches).map((item) => item.id), [
      'mock-case-004',
    ]);
  });

  for (final width in [320.0, 375.0, 390.0, 389.0, 600.0]) {
    testWidgets('Cards use the requested column count at width $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: CasesPage()));
      await tester.pumpAndSettle();
      final cards = find.byType(CaseCard);
      final columns = width < 390 ? 2 : 3;
      expect(
        tester.getSize(cards.first).width,
        closeTo((width - 32 - 8 * (columns - 1)) / columns, 0.01),
      );
      expect(
        tester.getTopLeft(cards.at(columns - 1)).dy,
        tester.getTopLeft(cards.first).dy,
      );
      expect(
        tester.getTopLeft(cards.at(columns)).dy,
        greaterThan(tester.getTopLeft(cards.first).dy),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Applying each issue type displays its matching mock cases', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: CasesPage()));
    await tester.pumpAndSettle();
    for (final value in CaseFilterOptions.values[CaseFilterGroup.issueType]!) {
      await tester.tap(find.byTooltip('Filter Cases'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Reset').last);
      await tester.pump();
      await tester.tap(find.text(value).last);
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();
      final shown = tester.widgetList<CaseCard>(find.byType(CaseCard));
      expect(
        shown.map((card) => card.caseItem.id).toSet(),
        mockCases
            .where((item) => item.issueType == value)
            .map((item) => item.id)
            .toSet(),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Large status tabs scroll with the animated underline', (
    tester,
  ) async {
    CaseStatus? status;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 288,
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: StatefulBuilder(
                  builder: (context, setState) => CaseStatusTabs(
                    cases: mockCases,
                    selectedStatus: status,
                    onChanged: (value) => setState(() => status = value),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scroll = find.descendant(
      of: find.byType(CaseStatusTabs),
      matching: find.byType(SingleChildScrollView),
    );
    await tester.drag(scroll, const Offset(-1000, 0));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Resolved(2)'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Resolved(2)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resolved(2)'));
    await tester.pumpAndSettle();
    final indicator = tester.widget<AnimatedPositioned>(
      find.byType(AnimatedPositioned),
    );
    final ink = find.ancestor(
      of: find.text('Resolved(2)'),
      matching: find.byType(InkWell),
    );
    final indicatorBox = find.descendant(
      of: find.byType(AnimatedPositioned),
      matching: find.byType(ColoredBox),
    );
    expect(
      tester.getTopLeft(indicatorBox).dx,
      closeTo(tester.getTopLeft(ink).dx, 0.01),
    );
    expect(indicator.width, closeTo(tester.getSize(ink).width, 0.01));
    expect(status, CaseStatus.resolved);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Large sort menu labels and check fit at width 320', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: CaseSortMenu(
            selectedOrder: CaseSortOrder.newest,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Sort Cases'));
    await tester.pumpAndSettle();
    expect(find.text('Oldest'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
