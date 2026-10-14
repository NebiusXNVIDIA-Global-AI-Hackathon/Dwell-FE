import 'package:dwell/core/widgets/bottom_nav_bar.dart';
import 'package:dwell/features/cases/data/mock_cases.dart';
import 'package:dwell/features/cases/models/case_model.dart';
import 'package:dwell/features/cases/pages/case_created_page.dart';
import 'package:dwell/features/cases/widgets/list/case_creation_toast.dart';
import 'package:dwell/features/cases/widgets/list/case_search_tabs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'description_step_test.dart' show openDescription;
import 'helpers/case_creation_test_harness.dart';

void main() {
  setUpAll(loadCreationTestFonts);
  for (final size in [
    const Size(320, 568),
    const Size(375, 667),
    const Size(390, 844),
    const Size(430, 932),
    const Size(1280, 900),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('Full demo flow at $size/$scale returns to Logged once', (
        tester,
      ) async {
        final count = mockCases.length;
        final h = await openDescription(
          tester,
          size: size,
          scale: scale,
          // A 50px native inset + the unchanged 20px gap exercises the same
          // remaining content height as Web's 70px header padding.
          topInset: 50,
          useAnalysisRoute: true,
        );
        await h.enter('A ceiling leak');
        await tester.pumpAndSettle();
        final skip = scale == 1.5;
        final complete = skip
            ? find.byKey(const ValueKey('description-skip'))
            : h.nextButton;
        await tester.ensureVisible(complete);
        await tester.pumpAndSettle();
        await tester.tap(complete);
        await tester.pumpAndSettle();
        final result = tester
            .widget<CaseCreatedPage>(find.byType(CaseCreatedPage))
            .result;
        expect(result.isDemo, true);
        expect(result.input.draft.description, skip ? '' : 'A ceiling leak');
        final evidence = result.input.evidence.single;
        expect(evidence.isDisposed, false);
        expect(tester.takeException(), isNull);

        final back = find.widgetWithText(FilledButton, 'Back to main');
        await tester.ensureVisible(back);
        final action = tester.widget<FilledButton>(back).onPressed!;
        action();
        action();
        await tester.pumpAndSettle();
        expect(h.router.canPop(), false);
        expect(h.router.routeInformationProvider.value.uri.path, '/cases');
        expect(
          tester.widget<BottomNavBar>(find.byType(BottomNavBar)).currentIndex,
          1,
        );
        expect(
          tester
              .widget<CaseStatusTabs>(find.byType(CaseStatusTabs))
              .selectedStatus,
          CaseStatus.logged,
        );
        expect(find.byType(CaseCreationToast), findsOneWidget);
        expect(find.text('Demo case created'), findsOneWidget);
        expect(find.text('Case created successfully'), findsNothing);
        expect(evidence.isDisposed, true);
        expect(mockCases.length, count);
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(milliseconds: 2700));
        await tester.pumpAndSettle();
        expect(find.byType(CaseCreationToast), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
