import 'package:dwell/core/theme.dart';
import 'package:dwell/features/cases/pages/evidence_guide_page.dart';
import 'package:dwell/features/cases/widgets/creation/case_creation_header.dart';
import 'package:dwell/features/cases/widgets/creation/steps/affected_area_step.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'case_creation_layout_test.dart' show collectLayoutProblems;
import 'helpers/case_creation_test_harness.dart';

Finder get play => find.byWidgetPredicate(
  (w) =>
      w is SvgPicture &&
      w.bytesLoader is SvgAssetLoader &&
      (w.bytesLoader as SvgAssetLoader).assetName ==
          'assets/icons/case/play.svg',
);
void verifyCards(WidgetTester tester) {
  final images = find.descendant(
    of: find.byType(EvidenceGuidePage),
    matching: find.byType(Image),
  );
  expect(images, findsNWidgets(4));
  final names = [
    'overall_view.png',
    'close_up.png',
    'video_recording.png',
    'surrounding_area.png',
  ];
  for (var i = 0; i < 4; i++) {
    final image = tester.widget<Image>(images.at(i));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/evidence_guide/${names[i]}',
    );
    expect(image.fit, BoxFit.cover);
    final stack = find
        .ancestor(of: images.at(i), matching: find.byType(Stack))
        .first;
    expect(
      find.descendant(of: stack, matching: play),
      i == 2 ? findsOneWidget : findsNothing,
    );
    final rect = tester.getRect(images.at(i));
    expect(rect.width, rect.height);
    if (i == 2) expect(tester.getRect(play).center, rect.center);
  }
  expect(tester.widget<SvgPicture>(play).excludeFromSemantics, isTrue);
  expect(
    find.descendant(
      of: find.byType(EvidenceGuidePage),
      matching: find.byType(LinearProgressIndicator),
    ),
    findsNothing,
  );
}

void main() {
  setUpAll(loadCreationTestFonts);
  for (final size in [
    const Size(320, 568),
    const Size(375, 667),
    const Size(393, 844),
    const Size(430, 932),
  ]) {
    for (final scale in [1.0, 1.3, 1.5]) {
      testWidgets(
        'Four guide cards and only video has centered decorative Play at $size scale $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await tester.pumpWidget(
            MaterialApp(
              theme: buildTheme(Brightness.light),
              home: const EvidenceGuidePage(),
            ),
          );
          await tester.pumpAndSettle();
          verifyCards(tester);
          final problems = <String>[];
          collectLayoutProblems(
            tester,
            find.byType(EvidenceGuidePage),
            'guide',
            problems,
          );
          expect(problems, isEmpty, reason: problems.join('\n'));
          await tester.ensureVisible(find.text('4. Surrounding area'));
          await tester.pumpAndSettle();
          expect(
            find.text('4. Surrounding area').hitTestable(),
            findsOneWidget,
          );
          expect(
            find.text('Start Adding Evidence').hitTestable(),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'Step 4 guide Back preserves all Other inputs and Start reaches Step 5',
    (tester) async {
      final h = await CreationHarness.start(tester, direct: true);
      await h.choose('Plumbing');
      await h.next();
      await h.choose('Other');
      await h.enter('leak');
      await h.next();
      await h.choose('Other');
      await h.enter('garage');
      await h.next();
      await h.choose('Other');
      await h.enter('corner');
      await h.next();
      expect(find.byType(EvidenceGuidePage), findsOneWidget);
      verifyCards(tester);
      await h.tap(
        find.descendant(
          of: find.byType(EvidenceGuidePage),
          matching: find.byTooltip('Back'),
        ),
      );
      h.expectStep(4);
      expect(h.input, 'corner');
      final area = tester.widget<AffectedAreaStep>(h.step);
      expect(area.issueSummary, 'Plumbing - leak');
      expect(area.locationSummary, 'garage');
      expect(area.selectedArea, 'Other');
      await h.next();
      await h.tap(find.text('Start Adding Evidence'));
      expect(find.byType(EvidenceGuidePage), findsNothing);
      expect(
        tester
            .widget<CaseCreationHeader>(find.byType(CaseCreationHeader))
            .currentStep,
        5,
      );
      expect(find.text('steps 5 of 7'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Entire Unit skips Step 4, system Back preserves state and Start reaches Step 5',
    (tester) async {
      final h = await CreationHarness.start(tester, direct: true);
      await h.toLocation();
      await h.choose('Entire Unit');
      await h.next();
      expect(find.byType(EvidenceGuidePage), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      h.expectStep(3);
      h.expectNext(true);
      await h.next();
      await h.tap(find.text('Start Adding Evidence'));
      expect(
        tester
            .widget<CaseCreationHeader>(find.byType(CaseCreationHeader))
            .currentStep,
        5,
      );
      expect(find.byType(AffectedAreaStep), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
