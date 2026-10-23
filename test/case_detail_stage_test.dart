import 'package:dwell/features/assistant/pages/chat_page.dart';
import 'package:dwell/features/case_detail/data/case_stage_mock.dart';
import 'package:dwell/features/case_detail/models/case_stage.dart';
import 'package:dwell/features/case_detail/models/timeline_step.dart';
import 'package:dwell/features/case_detail/presentation/screens/case_detail_screen.dart';
import 'package:dwell/features/case_detail/presentation/screens/case_placeholder_screen.dart';
import 'package:dwell/features/case_detail/presentation/widgets/case_stage_sheet.dart';
import 'package:dwell/features/case_detail/presentation/widgets/case_timeline.dart';
import 'package:dwell/features/case_detail/state/case_detail_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/case_detail_test_harness.dart';

void main() {
  setUpAll(loadCaseDetailTestFonts);

  for (final size in const [Size(375, 812), Size(390, 844), Size(430, 932)]) {
    testWidgets('Every stage lays out without overflow at $size', (
      tester,
    ) async {
      final h = await DetailHarness.open(tester, size: size);
      for (final stage in CaseStage.values) {
        h.controller.setStage(stage);
        await tester.pumpAndSettle();
        final content = caseStageContent(
          stage,
          createdAt: h.container.read(caseDetailProvider(h.id))!.createdAt,
        );
        expect(find.text(content.banner.headline), findsWidgets);
        expect(find.text(content.banner.action.label), findsOneWidget);
        expect(h.checklist, content.checklist, reason: stage.name);
        expect(tester.takeException(), isNull, reason: stage.name);
      }
    });
  }

  testWidgets('Badge follows the stage', (tester) async {
    final h = await DetailHarness.open(tester);
    expect(find.text('Logged'), findsOneWidget);
    h.controller.setStage(CaseStage.reported311);
    await tester.pumpAndSettle();
    expect(find.text('In Progress'), findsOneWidget);
    h.controller.setStage(CaseStage.resolved);
    await tester.pumpAndSettle();
    expect(find.text('Resolved'), findsWidgets);
  });

  testWidgets('Overdue stages render an alert node', (tester) async {
    final h = await DetailHarness.open(tester);
    h.controller.setStage(CaseStage.responseOverdue);
    await tester.pumpAndSettle();
    final timeline = tester.widget<CaseTimeline>(find.byType(CaseTimeline));
    expect(
      timeline.steps.map((step) => step.state),
      contains(TimelineStepState.alert),
    );
    expect(find.text('!'), findsOneWidget);
  });

  testWidgets('Update status opens the sheet and switches the stage', (
    tester,
  ) async {
    final h = await DetailHarness.open(tester, id: 'mock-case-001');
    expect(find.text('24 hours left'), findsOneWidget);
    await h.tap(find.text('Got a Reply? Update Status'));
    expect(find.byType(CaseStageSheet), findsOneWidget);
    await h.tap(find.text('Repair day'));
    expect(find.byType(CaseStageSheet), findsNothing);
    expect(find.text('Repair D-Day'), findsOneWidget);
    expect(
      h.checklist.first,
      'Ask about the cause and fix, in writing if possible',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Talk to Deaver opens the case chat', (tester) async {
    final h = await DetailHarness.open(tester);
    h.controller.setStage(CaseStage.followUpOverdue);
    await tester.pumpAndSettle();
    await h.tap(find.text('Talk to Deaver'));
    expect(find.byType(ChatPage), findsOneWidget);
    expect(tester.widget<ChatPage>(find.byType(ChatPage)).caseNo, 'C-003');
  });

  testWidgets('Placeholder actions open and return to Case Detail', (
    tester,
  ) async {
    final h = await DetailHarness.open(tester);
    h.controller.setStage(CaseStage.landlordRefused);
    await tester.pumpAndSettle();
    await h.tap(find.text('Time to Escalate'));
    expect(find.byType(CasePlaceholderScreen), findsOneWidget);
    await h.tap(find.bySemanticsLabel('Back'));
    expect(find.byType(CasePlaceholderScreen), findsNothing);
    expect(find.byType(CaseDetailScreen), findsOneWidget);
  });
}
