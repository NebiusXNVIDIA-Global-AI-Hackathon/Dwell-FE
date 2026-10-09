import 'package:dwell/features/cases/widgets/creation/case_creation_header.dart';
import 'package:dwell/features/cases/widgets/creation/case_creation_summary_row.dart';
import 'package:dwell/features/cases/widgets/creation/dialogs/case_exit_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/case_creation_test_harness.dart';

List<Offset> corners(Rect r) => [
  r.topLeft + const Offset(1, 1),
  r.topRight + const Offset(-1, 1),
  r.bottomLeft + const Offset(1, -1),
  r.bottomRight - const Offset(1, 1),
];
List<Offset> edges(Rect r) => [
  r.topCenter + const Offset(0, 1),
  r.centerRight - const Offset(1, 0),
  r.bottomCenter - const Offset(0, 1),
  r.centerLeft + const Offset(1, 0),
];

Rect target(WidgetTester tester, Finder f) {
  final r = tester.getRect(f);
  expect(r.width, greaterThanOrEqualTo(44));
  expect(r.height, greaterThanOrEqualTo(44));
  return r;
}

void main() {
  setUpAll(loadCreationTestFonts);
  for (final size in [
    const Size(320, 568),
    const Size(393, 844),
    const Size(430, 932),
  ]) {
    for (final scale in [1.0, 1.3, 1.5]) {
      testWidgets(
        'Actual edge taps and unique button semantics at $size scale $scale',
        (tester) async {
          final handle = tester.ensureSemantics();
          try {
            final h = await CreationHarness.start(
              tester,
              size: size,
              textScale: scale,
              direct: true,
            );
            await h.toArea();
            final header = find.byType(CaseCreationHeader);
            final visual = find.descendant(
              of: header,
              matching: find.byWidgetPredicate(
                (w) => w is SizedBox && w.width == 33 && w.height == 33,
              ),
            );
            expect(tester.getSize(visual), const Size(33, 33));
            final backRect = target(tester, h.headerBack);
            expect(tester.getRect(header).contains(backRect.topLeft), isTrue);
            expect(
              tester
                  .getRect(header)
                  .contains(backRect.bottomRight - const Offset(0.01, 0.01)),
              isTrue,
            );
            expect(find.bySemanticsLabel('Back'), findsOneWidget);
            final backData = tester
                .getSemantics(find.bySemanticsLabel('Back'))
                .getSemanticsData();
            expect(backData.flagsCollection.isButton, isTrue);
            for (final point in corners(backRect)) {
              await tester.tapAt(point);
              await tester.pumpAndSettle();
              expect(find.byType(CaseExitDialog), findsOneWidget);
              final stay = find.widgetWithText(TextButton, 'Stay');
              final leave = find.widgetWithText(TextButton, 'Leave');
              final sr = target(tester, stay);
              final lr = target(tester, leave);
              expect(sr.overlaps(lr), isFalse);
              expect(lr.left - sr.right, closeTo(1, 0.01));
              expect(find.bySemanticsLabel('Stay'), findsOneWidget);
              expect(find.bySemanticsLabel('Leave'), findsOneWidget);
              expect(
                tester
                    .getSemantics(find.bySemanticsLabel('Stay'))
                    .getSemanticsData()
                    .flagsCollection
                    .isButton,
                isTrue,
              );
              expect(
                tester
                    .getSemantics(find.bySemanticsLabel('Leave'))
                    .getSemanticsData()
                    .flagsCollection
                    .isButton,
                isTrue,
              );
              // Each pass exercises a different edge of Stay.
              final index = corners(backRect).indexOf(point);
              await tester.tapAt(edges(sr)[index]);
              await tester.pumpAndSettle();
              expect(find.byType(CaseExitDialog), findsNothing);
              h.expectStep(4);
            }
            for (var index = 0; index < 4; index++) {
              final rows = find.byType(CaseCreationSummaryRow);
              final issue = find.descendant(
                of: rows.first,
                matching: find.byWidgetPredicate(
                  (w) => w is Semantics && w.properties.label == 'Edit',
                ),
              );
              final location = find.descendant(
                of: rows.last,
                matching: find.byWidgetPredicate(
                  (w) => w is Semantics && w.properties.label == 'Edit',
                ),
              );
              await tester.ensureVisible(issue);
              await tester.pump();
              final ir = target(tester, issue);
              final lr = target(tester, location);
              expect(ir.overlaps(lr), isFalse);
              expect(find.bySemanticsLabel('Edit'), findsNWidgets(2));
              final semantic = find.descendant(
                of: rows.first,
                matching: find.byWidgetPredicate(
                  (w) => w is Semantics && w.properties.label == 'Edit',
                ),
              );
              expect(
                tester
                    .getSemantics(semantic)
                    .getSemanticsData()
                    .flagsCollection
                    .isButton,
                isTrue,
              );
              await tester.tapAt(corners(ir)[index]);
              await tester.pumpAndSettle();
              h.expectStep(1);
              await h.next();
              await h.next();
              await h.next();
              h.expectStep(4);
              final locationTarget = find.descendant(
                of: find.byType(CaseCreationSummaryRow).last,
                matching: find.byWidgetPredicate(
                  (w) => w is Semantics && w.properties.label == 'Edit',
                ),
              );
              await tester.ensureVisible(locationTarget);
              await tester.pump();
              await tester.tapAt(
                corners(target(tester, locationTarget))[index],
              );
              await tester.pumpAndSettle();
              h.expectStep(3);
              await h.next();
              h.expectStep(4);
            }
            // All four straight edges are inside the rounded dialog clip.
            for (var edge = 0; edge < 4; edge++) {
              await tester.tapAt(
                tester.getRect(h.headerBack).bottomCenter - const Offset(0, 1),
              );
              await tester.pumpAndSettle();
              final leave = find.widgetWithText(TextButton, 'Leave');
              await tester.tapAt(edges(target(tester, leave))[edge]);
              await tester.pumpAndSettle();
              expect(h.page, findsNothing);
              if (edge < 3) await h.openNewCase();
            }
            expect(tester.takeException(), isNull);
          } finally {
            handle.dispose();
          }
        },
      );
    }
  }
}
