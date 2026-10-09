import 'package:dwell/features/cases/pages/evidence_guide_page.dart';
import 'package:dwell/features/cases/widgets/creation/case_creation_header.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/case_creation_test_harness.dart';

void main() {
  setUpAll(loadCreationTestFonts);
  for (final topInset in [24.0, 48.0]) {
    testWidgets(
      'creation headers follow SafeArea with $topInset system inset',
      (tester) async {
        final h = await CreationHarness.start(tester, direct: true);
        tester.view.padding = FakeViewPadding(top: topInset, bottom: 24);
        tester.view.viewPadding = FakeViewPadding(top: topInset, bottom: 24);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);
        await tester.pumpAndSettle();
        void checkStep(int step) {
          h.expectStep(step);
          final header = find.descendant(
            of: h.page,
            matching: find.byType(CaseCreationHeader),
          );
          expect(tester.getRect(header).top, topInset + 20);
          expect(tester.getRect(header).height, 59);
          expect(tester.getRect(h.nextButton).bottom, 844 - 24 - 24);
          expect(tester.takeException(), isNull);
        }

        checkStep(1);
        await h.choose('Plumbing');
        await h.next();
        checkStep(2);
        await h.choose('Sink Issue');
        await h.next();
        checkStep(3);
        await h.choose('Kitchen');
        await h.next();
        checkStep(4);
        // Keyboard visibility must not change the top design gap.
        tester.view.viewInsets = const FakeViewPadding(bottom: 250);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.byType(CaseCreationHeader)).top,
          topInset + 20,
        );
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        await h.choose('Ceiling');
        await h.next();
        final guide = find.byType(EvidenceGuidePage);
        expect(
          tester
              .getRect(
                find.descendant(
                  of: guide,
                  matching: find.byType(CaseCreationHeader),
                ),
              )
              .top,
          topInset + 20,
        );
        final start = find.descendant(
          of: guide,
          matching: find.widgetWithText(FilledButton, 'Start Adding Evidence'),
        );
        expect(tester.getRect(start).bottom, 844 - 24 - 38);
        await h.tap(start);
        checkStep(5);
      },
    );
  }
}
