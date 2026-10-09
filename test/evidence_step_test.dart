import 'package:dwell/features/cases/widgets/creation/evidence/evidence_add_sheet.dart';
import 'package:dwell/features/cases/widgets/creation/steps/evidence_step.dart';
import 'package:dwell/features/cases/widgets/creation/dialogs/case_exit_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dwell/features/cases/controllers/case_creation_controller.dart';
import 'package:material_ui/material_ui.dart';

import 'case_creation_layout_test.dart' show collectLayoutProblems;
import 'helpers/case_creation_test_harness.dart';

Future<CreationHarness> enterEvidence(
  WidgetTester tester, {
  Size size = const Size(393, 844),
  double scale = 1,
}) async {
  final h = await CreationHarness.start(
    tester,
    direct: true,
    size: size,
    textScale: scale,
  );
  await h.toArea();
  await h.choose('Other');
  await h.enter('corner');
  await h.next();
  await h.tap(find.text('Start Adding Evidence'));
  return h;
}

Finder get add => find.byKey(const ValueKey('evidence-add'));
Finder get sheet => find.byType(EvidenceAddSheet);

void main() {
  setUpAll(loadCreationTestFonts);
  test('Entering and reentering evidence retains every draft field', () {
    final c = CaseCreationController();
    c.selectIssueType('Plumbing');
    c.next();
    c.selectSpecificIssue('Other');
    c.setOtherIssue('leak');
    c.next();
    c.selectLocation('Other');
    c.setOtherLocation('garage');
    c.next();
    c.selectAffectedArea('Other');
    c.setOtherAffectedArea('corner');
    final draft = c.draft;
    for (var i = 0; i < 2; i++) {
      c.beginEvidence();
      expect(c.currentStep, 5);
      expect(c.draft, same(draft));
      expect(draft.issueType, 'Plumbing');
      expect(draft.specificIssue, 'Other');
      expect(draft.otherIssue, 'leak');
      expect(draft.location, 'Other');
      expect(draft.otherLocation, 'garage');
      expect(draft.affectedArea, 'Other');
      expect(draft.otherAffectedArea, 'corner');
      expect(c.canGoNext, isFalse);
      if (i == 0) {
        c.editLocation();
        c.next();
      }
    }
  });
  testWidgets(
    'Every source shows pressed border, closes without evidence and can reopen',
    (tester) async {
      final h = await enterEvidence(tester);
      for (final option in EvidenceAddSheet.options) {
        await h.tap(add);
        final menu = find.byKey(ValueKey(option.$1));
        await tester.ensureVisible(menu);
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(tester.getCenter(menu));
        await tester.pumpAndSettle();
        final material = find
            .ancestor(of: menu, matching: find.byType(Material))
            .first;
        final shape =
            tester.widget<Material>(material).shape! as RoundedRectangleBorder;
        expect(shape.side.color, const Color(0xFF243B53));
        await gesture.up();
        await tester.pumpAndSettle();
        expect(sheet, findsNothing);
        h.expectStep(5);
        expect(find.byType(EvidenceStep), findsOneWidget);
        h.expectNext(false);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Guide enters Step 5; sheet dismisses, reopens, preserves input and Exit policy',
    (tester) async {
      final h = await enterEvidence(tester);
      h.expectStep(5);
      expect(
        find.text(
          'Add evidence that clearly shows the issue and affected area.',
        ),
        findsOneWidget,
      );
      expect(tester.getSize(add), const Size(96, 96));
      expect(find.text('Check'), findsOneWidget);
      h.expectNext(false);
      await h.tap(add);
      expect(sheet, findsOneWidget);
      for (final option in EvidenceAddSheet.options) {
        expect(find.text(option.$2), findsOneWidget);
        expect(find.text(option.$3), findsOneWidget);
      }
      final plusMaterial = find.descendant(
        of: add,
        matching: find.byType(Material),
      );
      expect(
        tester.widget<Material>(plusMaterial).color,
        const Color(0xFFA6A6A6),
      );
      await tester.tapAt(const Offset(10, 200));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      await h.tap(add);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(find.byType(CaseExitDialog), findsNothing);
      h.expectStep(5);
      await h.tap(add);
      await tester.drag(sheet, const Offset(0, 650));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      await h.tap(add);
      final menu = find.byKey(const ValueKey(EvidenceSource.photo));
      final gesture = await tester.startGesture(tester.getCenter(menu));
      await tester.pumpAndSettle();
      final material = find
          .ancestor(of: menu, matching: find.byType(Material))
          .first;
      final shape =
          tester.widget<Material>(material).shape! as RoundedRectangleBorder;
      expect(shape.side.color, const Color(0xFF243B53));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      h.expectNext(false);
      h.expectStep(5);
      await h.tap(h.headerBack);
      expect(find.byType(CaseExitDialog), findsOneWidget);
      await h.tap(find.text('Stay'));
      h.expectStep(5);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(375, 667),
    const Size(393, 844),
    const Size(430, 932),
  ]) {
    for (final scale in [1.0, 1.3, 1.5]) {
      testWidgets(
        'Evidence and scrollable sheet layout at SIZE scale SCALE'
            .replaceAll('SIZE', size.toString())
            .replaceAll('SCALE', scale.toString()),
        (tester) async {
          final h = await enterEvidence(tester, size: size, scale: scale);
          h.expectStep(5);
          h.expectNext(false);
          final problems = <String>[];
          collectLayoutProblems(tester, h.page, 'evidence', problems);
          expect(problems, isEmpty, reason: problems.join());
          final buttonRect = tester.getRect(h.nextButton);
          await h.tap(add);
          expect(sheet, findsOneWidget);
          collectLayoutProblems(tester, sheet, 'sheet', problems);
          expect(problems, isEmpty, reason: problems.join());
          await tester.ensureVisible(find.text('Upload Documents'));
          await tester.pumpAndSettle();
          expect(find.text('Upload Documents').hitTestable(), findsOneWidget);
          await h.tap(find.byKey(const ValueKey(EvidenceSource.document)));
          expect(sheet, findsNothing);
          expect(tester.getRect(h.nextButton), buttonRect);
          h.expectNext(false);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
