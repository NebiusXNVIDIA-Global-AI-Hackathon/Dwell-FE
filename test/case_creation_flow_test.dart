import 'package:dwell/features/cases/pages/evidence_guide_page.dart';
import 'package:dwell/features/cases/pages/cases_page.dart';
import 'package:dwell/features/cases/widgets/creation/case_area_card.dart';
import 'package:dwell/features/cases/widgets/creation/case_option_card.dart';
import 'package:dwell/features/cases/widgets/creation/dialogs/case_exit_dialog.dart';
import 'package:dwell/features/cases/widgets/creation/dialogs/safety_notice_dialog.dart';
import 'package:dwell/features/cases/widgets/creation/steps/affected_area_step.dart';
import 'package:dwell/features/cases/widgets/creation/steps/issue_type_step.dart';
import 'package:dwell/features/cases/widgets/creation/steps/location_step.dart';
import 'package:dwell/features/cases/widgets/creation/steps/specific_issue_step.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/case_creation_test_harness.dart';

void main() {
  setUpAll(loadCreationTestFonts);

  testWidgets(
    'New Case opens the real route and advances steps 1–4 with progress',
    (tester) async {
      final h = await CreationHarness.start(tester);
      h.expectStep(1);
      h.expectNext(false);
      expect(find.byType(BottomNavigationBar), findsNothing);
      // Current production has only Next; Edit is used to revisit earlier inputs.
      expect(
        find.descendant(of: h.bottom, matching: find.text('Back')),
        findsNothing,
      );
      await h.choose('Plumbing');
      h.expectNext(true);
      expect(
        tester.widget<IssueTypeStep>(h.step).selectedIssueType,
        'Plumbing',
      );
      await h.next();
      h.expectStep(2);
      h.expectNext(false);
      await h.choose('Sink Issue');
      h.expectNext(true);
      await h.next();
      h.expectStep(3);
      h.expectNext(false);
      await h.choose('Kitchen');
      h.expectNext(true);
      await h.next();
      h.expectStep(4);
      h.expectNext(false);
      expect(find.text('Plumbing - Sink Issue'), findsOneWidget);
      await h.choose('Cabinet');
      h.expectNext(true);
      expect(tester.widget<AffectedAreaStep>(h.step).selectedArea, 'Cabinet');
      expect(find.text('Kitchen - Cabinet'), findsOneWidget);
      final selected = find.byWidgetPredicate(
        (w) => w is CaseAreaCard && w.selected,
      );
      expect(tester.widget<CaseAreaCard>(selected).label, 'Cabinet');
      expect(
        find.descendant(of: selected, matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
      await h.next();
      expect(find.byType(EvidenceGuidePage), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      h.expectStep(4);
      expect(tester.widget<AffectedAreaStep>(h.step).selectedArea, 'Cabinet');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Actual Edit navigation and same selections preserve issue, location and area',
    (tester) async {
      final h = await CreationHarness.start(tester);
      await h.toArea();
      await h.choose('Cabinet');
      await h.editIssue();
      h.expectStep(1);
      expect(
        tester.widget<IssueTypeStep>(h.step).selectedIssueType,
        'Plumbing',
      );
      await h.choose('Plumbing');
      await h.next();
      h.expectStep(2);
      expect(
        tester.widget<SpecificIssueStep>(h.step).selectedIssue,
        'Sink Issue',
      );
      await h.choose('Sink Issue');
      await h.next();
      h.expectStep(3);
      expect(tester.widget<LocationStep>(h.step).selectedLocation, 'Kitchen');
      await h.choose('Kitchen');
      await h.next();
      expect(tester.widget<AffectedAreaStep>(h.step).selectedArea, 'Cabinet');
      await h.editLocation();
      h.expectStep(3);
      expect(tester.widget<LocationStep>(h.step).selectedLocation, 'Kitchen');
      await h.next();
      h.expectStep(4);
      expect(tester.widget<AffectedAreaStep>(h.step).selectedArea, 'Cabinet');
      h.expectNext(true);
    },
  );

  testWidgets(
    'Changing issue type clears dependent issue, location, area and Other inputs',
    (tester) async {
      final h = await CreationHarness.start(tester);
      await h.choose('Plumbing');
      await h.next();
      await h.choose('Other');
      await h.enter('old issue');
      await h.next();
      await h.choose('Other');
      await h.enter('old room');
      await h.next();
      await h.choose('Other');
      await h.enter('old corner');
      await h.editIssue();
      await h.choose('Water & Flooding');
      await h.next();
      expect(tester.widget<SpecificIssueStep>(h.step).selectedIssue, isNull);
      expect(tester.widget<SpecificIssueStep>(h.step).otherText, isEmpty);
      h.expectNext(false);
      await h.choose('Other');
      expect(h.input, isEmpty);
      await h.enter('new issue');
      await h.next();
      expect(tester.widget<LocationStep>(h.step).selectedLocation, isNull);
      expect(tester.widget<LocationStep>(h.step).otherText, isEmpty);
      h.expectNext(false);
      await h.choose('Kitchen');
      await h.next();
      expect(tester.widget<AffectedAreaStep>(h.step).selectedArea, isNull);
      expect(tester.widget<AffectedAreaStep>(h.step).otherText, isEmpty);
      h.expectNext(false);
    },
  );

  testWidgets('Changing specific issue clears dependent location and area', (
    tester,
  ) async {
    final h = await CreationHarness.start(tester);
    await h.toArea();
    await h.choose('Other');
    await h.enter('old corner');
    await h.editIssue();
    await h.next();
    await h.choose('Faucet Issue');
    await h.next();
    expect(tester.widget<LocationStep>(h.step).selectedLocation, isNull);
    h.expectNext(false);
    await h.choose('Kitchen');
    await h.next();
    expect(tester.widget<AffectedAreaStep>(h.step).selectedArea, isNull);
    expect(tester.widget<AffectedAreaStep>(h.step).otherText, isEmpty);
  });

  testWidgets(
    'Changing location clears area and presents the new location options',
    (tester) async {
      final h = await CreationHarness.start(tester);
      await h.toArea();
      await h.choose('Other');
      await h.enter('old corner');
      await h.editLocation();
      await h.choose('Bathroom');
      await h.next();
      final step = tester.widget<AffectedAreaStep>(h.step);
      expect(step.location, 'Bathroom');
      expect(step.selectedArea, isNull);
      expect(step.otherText, isEmpty);
      h.expectNext(false);
      expect(find.text('Shower'), findsOneWidget);
      expect(find.text('Cabinet'), findsNothing);
    },
  );

  for (final issue in ['Other', 'Other Appliance']) {
    testWidgets(
      'Specific Issue $issue validates blanks, restores text and clears on change',
      (tester) async {
        final h = await CreationHarness.start(tester);
        final type = issue == 'Other Appliance' ? 'Appliances' : 'Plumbing';
        await h.choose(type);
        await h.next();
        await h.choose(issue);
        expect(h.field, findsOneWidget);
        expect(h.input, isEmpty);
        h.expectNext(false);
        await h.enter('');
        h.expectNext(false);
        await h.enter('   ');
        h.expectNext(false);
        await h.enter(' custom issue ');
        h.expectNext(true);
        await h.editIssue();
        await h.next();
        expect(h.input, ' custom issue ');
        h.expectNext(true);
        await h.choose(issue);
        expect(h.input, ' custom issue ');
        await h.choose(issue == 'Other' ? 'Sink Issue' : 'Refrigerator');
        expect(h.field, findsNothing);
        expect(tester.widget<SpecificIssueStep>(h.step).otherText, isEmpty);
        await h.choose(issue);
        expect(h.input, isEmpty);
        h.expectNext(false);
      },
    );
  }

  testWidgets(
    'Location Other validates whitespace, restores after Edit and clears on change',
    (tester) async {
      final h = await CreationHarness.start(tester);
      await h.toLocation();
      await h.choose('Other');
      expect(h.input, isEmpty);
      h.expectNext(false);
      await h.enter('   ');
      h.expectNext(false);
      await h.enter(' garage ');
      h.expectNext(true);
      await h.editIssue();
      await h.next();
      await h.next();
      expect(h.input, ' garage ');
      h.expectNext(true);
      await h.choose('Other');
      expect(h.input, ' garage ');
      await h.next();
      h.expectStep(4);
      expect(find.text('garage - '), findsOneWidget);
      await h.editLocation();
      expect(h.input, ' garage ');
      await h.choose('Kitchen');
      expect(h.field, findsNothing);
      expect(tester.widget<LocationStep>(h.step).otherText, isEmpty);
      await h.choose('Other');
      expect(h.input, isEmpty);
      h.expectNext(false);
    },
  );

  testWidgets(
    'Affected Area Other validates, restores through both Edits and Clear updates Next',
    (tester) async {
      final h = await CreationHarness.start(tester);
      await h.toArea();
      await h.choose('Other');
      expect(h.input, isEmpty);
      h.expectNext(false);
      await h.enter('');
      h.expectNext(false);
      await h.enter('  ');
      h.expectNext(false);
      await h.enter(' pipe corner ');
      h.expectNext(true);
      expect(find.text('Kitchen - pipe corner'), findsOneWidget);
      await h.editLocation();
      await h.next();
      expect(h.input, ' pipe corner ');
      h.expectNext(true);
      await h.editIssue();
      await h.next();
      await h.next();
      await h.next();
      expect(h.input, ' pipe corner ');
      h.expectNext(true);
      await h.choose('Other');
      expect(h.input, ' pipe corner ');
      await h.tap(
        find.descendant(of: h.page, matching: find.byTooltip('Clear')),
      );
      expect(h.input, isEmpty);
      h.expectNext(false);
      expect(tester.widget<AffectedAreaStep>(h.step).otherText, isEmpty);
      await h.enter('another corner');
      await h.choose('Wall');
      expect(h.field, findsNothing);
      expect(tester.widget<AffectedAreaStep>(h.step).otherText, isEmpty);
      await h.choose('Other');
      expect(h.input, isEmpty);
      h.expectNext(false);
    },
  );

  testWidgets('Entire Unit opens the guide and Back restores Step 3', (
    tester,
  ) async {
    final h = await CreationHarness.start(tester);
    await h.toLocation();
    await h.choose('Entire Unit');
    h.expectNext(true);
    expect(find.text("We'll skip Step 4 · Affected Area"), findsOneWidget);
    await h.next();
    expect(find.byType(EvidenceGuidePage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    h.expectStep(3);
    expect(tester.widget<LocationStep>(h.step).selectedLocation, 'Entire Unit');
    expect(find.byType(AffectedAreaStep), findsNothing);
  });

  final hazards = <(String, String, SafetyNoticeType)>[
    ('Electricity', 'Exposed Wiring', SafetyNoticeType.electrical),
    ('Electricity', 'Sparks / Burning Smell', SafetyNoticeType.electrical),
    ('Water & Flooding', 'Flooding', SafetyNoticeType.flooding),
  ];
  for (final (type, issue, notice) in hazards) {
    testWidgets(
      '$type / $issue opens one safety modal, blocks Back, continues and repeats on reselect',
      (tester) async {
        final h = await CreationHarness.start(tester);
        await h.choose(type);
        await h.next();
        expect(find.byType(SafetyNoticeDialog), findsNothing);
        await h.choose(issue);
        expect(find.byType(SafetyNoticeDialog), findsOneWidget);
        expect(
          tester
              .widget<SafetyNoticeDialog>(find.byType(SafetyNoticeDialog))
              .type,
          notice,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(SafetyNoticeDialog), findsOneWidget);
        expect(find.byType(CaseExitDialog), findsNothing);
        // The modal barrier also prevents a tap on the page from duplicating it.
        await tester.tapAt(const Offset(2, 2));
        await tester.pump();
        expect(find.byType(SafetyNoticeDialog), findsOneWidget);
        await h.tap(find.widgetWithText(TextButton, 'I’m Safe — Continue'));
        expect(find.byType(SafetyNoticeDialog), findsNothing);
        h.expectStep(2);
        h.expectNext(true);
        expect(tester.widget<SpecificIssueStep>(h.step).selectedIssue, issue);
        await h.next();
        h.expectStep(3);
        await h.editIssue();
        await h.next();
        await h.choose(issue);
        expect(find.byType(SafetyNoticeDialog), findsOneWidget);
        await h.tap(find.widgetWithText(TextButton, 'Leave'));
        expect(h.page, findsNothing);
        expect(find.byType(CasesPage), findsOneWidget);
        expect(find.byType(CaseExitDialog), findsNothing);
      },
    );
  }

  testWidgets(
    'Gas safety opens on each step 2 entry and preserves selected issue on Continue',
    (tester) async {
      final h = await CreationHarness.start(tester);
      await h.choose('Gas');
      await h.next();
      expect(
        tester.widget<SafetyNoticeDialog>(find.byType(SafetyNoticeDialog)).type,
        SafetyNoticeType.gas,
      );
      await h.tap(find.widgetWithText(TextButton, 'I’m Safe — Continue'));
      h.expectStep(2);
      h.expectNext(false);
      await h.choose('Gas Shut Off');
      expect(find.byType(SafetyNoticeDialog), findsNothing);
      await h.editIssue();
      await h.next();
      expect(find.byType(SafetyNoticeDialog), findsOneWidget);
      await h.tap(find.widgetWithText(TextButton, 'I’m Safe — Continue'));
      expect(
        tester.widget<SpecificIssueStep>(h.step).selectedIssue,
        'Gas Shut Off',
      );
      h.expectNext(true);
      await h.editIssue();
      await h.next();
      await h.tap(find.widgetWithText(TextButton, 'Leave'));
      expect(h.page, findsNothing);
      expect(find.byType(CasesPage), findsOneWidget);
    },
  );

  testWidgets(
    'Nonhazardous electricity, water and Ceiling never open safety guidance',
    (tester) async {
      final h = await CreationHarness.start(tester);
      await h.choose('Electricity');
      await h.next();
      await h.choose('Outlet Not Working');
      expect(find.byType(SafetyNoticeDialog), findsNothing);
      await h.editIssue();
      await h.choose('Water & Flooding');
      await h.next();
      await h.choose('Water Leak');
      expect(find.byType(SafetyNoticeDialog), findsNothing);
      await h.next();
      await h.choose('Kitchen');
      await h.next();
      await h.choose('Ceiling');
      expect(find.byType(SafetyNoticeDialog), findsNothing);
      h.expectNext(true);
    },
  );

  testWidgets(
    'Header and system Back show Exit; Stay preserves input; Leave and reentry start fresh',
    (tester) async {
      final h = await CreationHarness.start(tester);
      await h.toArea();
      await h.choose('Other');
      await h.enter('saved corner');
      await h.tap(h.headerBack);
      expect(find.byType(CaseExitDialog), findsOneWidget);
      h.expectStep(4);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(CaseExitDialog), findsOneWidget);
      await h.tap(find.widgetWithText(TextButton, 'Stay'));
      h.expectStep(4);
      expect(h.input, 'saved corner');
      h.expectNext(true);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(CaseExitDialog), findsOneWidget);
      await h.tap(find.widgetWithText(TextButton, 'Leave'));
      expect(h.page, findsNothing);
      expect(find.byType(CasesPage), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      await h.openNewCase();
      h.expectStep(1);
      h.expectNext(false);
      expect(tester.widget<IssueTypeStep>(h.step).selectedIssueType, isNull);
      expect(
        tester
            .widgetList<CaseOptionCard>(find.byType(CaseOptionCard))
            .where((card) => card.selected),
        isEmpty,
      );
      await h.toArea();
      expect(tester.widget<AffectedAreaStep>(h.step).selectedArea, isNull);
      expect(tester.widget<AffectedAreaStep>(h.step).otherText, isEmpty);
    },
  );

  testWidgets(
    'Direct creation URL Leave uses the cases fallback when no page can pop',
    (tester) async {
      final h = await CreationHarness.start(tester, direct: true);
      expect(h.router.canPop(), isFalse);
      await h.tap(h.headerBack);
      await h.tap(find.widgetWithText(TextButton, 'Leave'));
      expect(h.page, findsNothing);
      expect(find.byType(CasesPage), findsOneWidget);
    },
  );
}
