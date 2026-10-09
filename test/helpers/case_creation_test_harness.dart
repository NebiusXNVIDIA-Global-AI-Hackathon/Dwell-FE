import 'package:dwell/app.dart';
import 'package:dwell/core/router.dart';
import 'package:dwell/features/cases/pages/case_creation_page.dart';
import 'package:dwell/features/cases/widgets/creation/case_creation_bottom.dart';
import 'package:dwell/features/cases/widgets/creation/case_creation_header.dart';
import 'package:dwell/features/cases/widgets/creation/steps/affected_area_step.dart';
import 'package:dwell/features/cases/widgets/creation/steps/issue_type_step.dart';
import 'package:dwell/features/cases/widgets/creation/steps/location_step.dart';
import 'package:dwell/features/cases/widgets/creation/steps/specific_issue_step.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

// Load real project fonts; no mocked controller, assets, dialogs or routes.
Future<void> loadCreationTestFonts() async {
  for (final family in ['Pretendard Variable', 'Roboto']) {
    final loader = FontLoader(family)
      ..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'));
    await loader.load();
  }
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

class CreationHarness {
  CreationHarness(this.tester, this.router);
  final WidgetTester tester;
  final GoRouter router;
  Finder get page => find.byType(CaseCreationPage);
  Finder get bottom =>
      find.descendant(of: page, matching: find.byType(CaseCreationBottom));
  Finder get nextButton =>
      find.descendant(of: bottom, matching: find.byType(FilledButton));
  Finder get field =>
      find.descendant(of: page, matching: find.byType(TextField));
  Finder get edits => find.descendant(
    of: page,
    matching: find.widgetWithText(TextButton, 'Edit'),
  );
  Finder get headerBack => find.descendant(
    of: find.descendant(of: page, matching: find.byType(CaseCreationHeader)),
    matching: find.byType(InkWell),
  );

  static Future<CreationHarness> start(
    WidgetTester tester, {
    Size size = const Size(393, 844),
    double textScale = 1,
    bool direct = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final container = ProviderContainer();
    final router = container.read(routerProvider);
    router.go(direct ? '/cases/new' : '/cases');
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DwellApp()),
    );
    await tester.pumpAndSettle(); // Initial route and SVG loading.
    final harness = CreationHarness(tester, router);
    if (!direct) await harness.openNewCase();
    return harness;
  }

  Future<void> openNewCase() async {
    final button = find.widgetWithText(ElevatedButton, 'New Case');
    expect(button, findsOneWidget);
    await tap(button);
    expect(GoRouterState.of(tester.element(page)).uri.path, '/cases/new');
  }

  Future<void> tap(Finder target) async {
    expect(target, findsOneWidget);
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.tap(target);
    await tester.pump();
    // Route/dialog completion can schedule another frame after endOfFrame.
    if (tester.binding.hasScheduledFrame) await tester.pumpAndSettle();
  }

  Finder get step => find.descendant(
    of: page,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is IssueTypeStep ||
          widget is SpecificIssueStep ||
          widget is LocationStep ||
          widget is AffectedAreaStep,
    ),
  );
  Future<void> choose(String label) =>
      tap(find.descendant(of: step, matching: find.text(label)));
  Future<void> next() => tap(nextButton);
  Future<void> editIssue() => tap(edits.first);
  Future<void> editLocation() => tap(edits.last);
  Future<void> enter(String value) async {
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await tester.pump();
  }

  String get input => tester.widget<TextField>(field).controller!.text;
  void expectNext(bool enabled) {
    expect(tester.widget<CaseCreationBottom>(bottom).enabled, enabled);
    expect(tester.widget<FilledButton>(nextButton).onPressed != null, enabled);
  }

  void expectStep(int number) {
    final header = tester.widget<CaseCreationHeader>(
      find.descendant(of: page, matching: find.byType(CaseCreationHeader)),
    );
    expect(header.currentStep, number);
    expect(header.totalSteps, 7);
    expect(
      find.descendant(of: page, matching: find.text('steps $number of 7')),
      findsOneWidget,
    );
    final progress = tester.widget<LinearProgressIndicator>(
      find.descendant(of: page, matching: find.byType(LinearProgressIndicator)),
    );
    expect(progress.value, closeTo(number / 7, 0.000001));
  }

  Future<void> toLocation({
    String issueType = 'Plumbing',
    String issue = 'Sink Issue',
  }) async {
    await choose(issueType);
    await next();
    await choose(issue);
    await next();
    expectStep(3);
  }

  Future<void> toArea({String location = 'Kitchen'}) async {
    await toLocation();
    await choose(location);
    await next();
    expectStep(4);
  }
}
