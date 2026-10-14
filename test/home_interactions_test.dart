import 'package:dwell/features/home/home_page.dart';
import 'package:dwell/features/home/data/home_mock_data.dart';
import 'package:dwell/features/home/data/home_severity_colors.dart';
import 'package:dwell/features/home/widgets/current_case_card.dart';
import 'package:dwell/features/cases/data/mock_cases.dart';
import 'package:dwell/features/cases/models/case_model.dart';
import 'package:dwell/core/widgets/bottom_nav_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/case_creation_test_harness.dart';
import 'home_page_test.dart' show openHome;

Finder tab(String id) => find.byKey(ValueKey('home-case-$id'));
Finder check(int index) => find.byKey(ValueKey('home-checklist-$index'));

Color tabColor(WidgetTester tester, String id) => tester
    .widget<Container>(
      find
          .descendant(
            of: tab(id),
            matching: find.byWidgetPredicate(
              (widget) => widget is Container && widget.color != null,
            ),
          )
          .first,
    )
    .color!;

void main() {
  setUpAll(loadCreationTestFonts);

  test('Severity palette uses existing enum and allows production palette replacement', () {
    expect(homeSeverityColor(CaseSeverity.high), const Color(0xFFEDABA8));
    expect(homeSeverityColor(CaseSeverity.medium), const Color(0xFFF0CE9C));
    expect(homeSeverityColor(CaseSeverity.low), const Color(0xFFE5E5E5));
    expect(
      homeSeverityColor(
        CaseSeverity.high,
        palette: const {CaseSeverity.high: Colors.blue},
      ),
      Colors.blue,
    );
  });

  testWidgets('Same case ID changing severity updates its tab color', (
    tester,
  ) async {
    final source = homeCases.first;
    Future<void> render(CaseSeverity severity) async {
      final original = source.caseItem;
      final model = CaseModel(
        id: original.id,
        title: original.title,
        status: original.status,
        severity: severity,
        issueType: original.issueType,
        location: original.location,
        affectedArea: original.affectedArea,
        isPublic: original.isPublic,
        createdAt: original.createdAt,
        updatedAt: original.updatedAt,
      );
      final data = HomeCaseData(
        caseItem: model,
        lastUpdate: source.lastUpdate,
        createdDate: source.createdDate,
        checklist: source.checklist,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CurrentCaseCard(data: data, cases: [data]),
        ),
      );
      await tester.pumpAndSettle();
    }

    await render(CaseSeverity.high);
    expect(
      tabColor(tester, source.number),
      homeSeverityColor(CaseSeverity.high),
    );
    await render(CaseSeverity.medium);
    expect(
      tabColor(tester, source.number),
      homeSeverityColor(CaseSeverity.medium),
    );
  });

  testWidgets(
    'Switching changes case information and keeps independent checklist state',
    (tester) async {
      await openHome(tester);
      expect(find.text('Water Leak'), findsOneWidget);
      expect(find.text('Case #C-006'), findsOneWidget);
      await tester.ensureVisible(check(0));
      await tester.tap(find.text(homeChecklist.first));
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(check(0)).value, true);
      await tester.ensureVisible(tab('C-005'));
      await tester.tap(tab('C-005'));
      await tester.pumpAndSettle();
      expect(find.text('Roaches'), findsOneWidget);
      expect(find.text('Case #C-005'), findsOneWidget);
      expect(find.text('Location: Livingroom - Corner'), findsOneWidget);
      expect(tester.widget<Checkbox>(check(0)).value, false);
      expect(find.byType(Checkbox), findsNWidgets(4));
      await tester.ensureVisible(check(1));
      await tester.tap(check(1));
      await tester.pumpAndSettle();
      await tester.ensureVisible(tab('C-006'));
      await tester.tap(tab('C-006'));
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(check(0)).value, true);
      expect(tester.widget<Checkbox>(check(1)).value, false);
      expect(find.byType(Checkbox), findsNWidgets(3));
      await tester.tap(tab('C-005'));
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(check(1)).value, true);
      await tester.ensureVisible(check(1));
      await tester.tap(check(1));
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(check(1)).value, false);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Tabs retain severity colors, press feedback and selected semantics',
    (tester) async {
      await openHome(tester);
      final pink = tabColor(tester, 'C-006');
      final orange = tabColor(tester, 'C-005');
      expect(pink, homeSeverityColor(homeCases[0].severity));
      expect(orange, homeSeverityColor(homeCases[1].severity));
      final gesture = await tester.startGesture(tester.getCenter(tab('C-005')));
      await tester.pumpAndSettle();
      expect(tabColor(tester, 'C-005'), isNot(orange));
      expect(find.text('Water Leak'), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tabColor(tester, 'C-006'), pink);
      expect(tabColor(tester, 'C-005'), orange);
      final selected = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.selected == true &&
            (widget.properties.label?.contains('C-005') ?? false),
      );
      expect(selected, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(375, 667),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Case tabs at $size/$scale have full hit targets and preserve scroll/nav',
        (tester) async {
          await openHome(tester, size: size, scale: scale);
          final scroll = find.byKey(const ValueKey('home-scroll'));
          final state = tester.state<ScrollableState>(
            find
                .descendant(of: scroll, matching: find.byType(Scrollable))
                .first,
          );
          state.position.jumpTo(5);
          await tester.pumpAndSettle();
          final nav = tester.getRect(find.byType(BottomNavBar));
          final target = tester.getRect(tab('C-005'));
          expect(target.size, const Size(48, 48));
          await tester.tapAt(target.bottomRight - const Offset(1, 1));
          await tester.pumpAndSettle();
          expect(find.text('Roaches'), findsOneWidget);
          expect(state.position.pixels, 5);
          expect(tester.getRect(find.byType(BottomNavBar)), nav);
          state.position.jumpTo(state.position.maxScrollExtent);
          await tester.pumpAndSettle();
          expect(
            tester
                .getRect(find.byKey(const ValueKey('home-check-unit')))
                .bottom,
            lessThan(nav.top),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'View Case keeps list routing, passes selected ID and never adds demo cases',
    (tester) async {
      final h = await openHome(tester);
      final count = mockCases.length;
      await tester.tap(tab('C-005'));
      await tester.pumpAndSettle();
      final button = find.widgetWithText(FilledButton, 'View Case');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(tester.getCenter(button));
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        tester
            .widget<Material>(
              find
                  .descendant(of: button, matching: find.byType(Material))
                  .first,
            )
            .color,
        const Color(0xFF506275),
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(h.router.routeInformationProvider.value.uri.path, '/cases');
      expect(h.router.state.extra, 'C-005');
      expect(mockCases.length, count);
    },
  );

  testWidgets(
    'View Case callback receives ID and detail click only reveals existing attention card',
    (tester) async {
      String? selectedId;
      await tester.pumpWidget(
        MaterialApp(home: HomePage(onViewCase: (id) => selectedId = id)),
      );
      await tester.pumpAndSettle();
      await tester.tap(tab('C-005'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'View Case'));
      await tester.pumpAndSettle();
      expect(selectedId, 'C-005');
      final detail = find.widgetWithText(TextButton, 'View detail');
      await tester.ensureVisible(detail);
      await tester.pumpAndSettle();
      await tester.tap(detail);
      await tester.pumpAndSettle();
      final unit = find.byKey(const ValueKey('home-check-unit'));
      expect(unit.hitTestable(), findsOneWidget);
      final gesture = await tester.startGesture(tester.getCenter(unit));
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        tester
            .widget<Material>(
              find.descendant(of: unit, matching: find.byType(Material)).first,
            )
            .color,
        const Color(0xFF416D76),
      );
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
