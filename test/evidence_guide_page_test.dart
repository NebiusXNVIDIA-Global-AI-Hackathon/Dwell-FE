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
    expect(rect.size, const Size(79, 66));
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
  testWidgets(
    'guide uses a full-screen page and repeated open/close preserves Step 4',
    (tester) async {
      final h = await CreationHarness.start(tester, direct: true);
      tester.view.padding = const FakeViewPadding(top: 48, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 48, bottom: 24);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await tester.pump();
      await h.toArea();
      await h.choose('Other');
      await h.enter('corner');

      for (var attempt = 0; attempt < 3; attempt++) {
        final next = tester.widget<FilledButton>(h.nextButton).onPressed!;
        next();
        next();
        await tester.pumpAndSettle();
        final guide = find.byType(EvidenceGuidePage);
        expect(guide, findsOneWidget);
        final route = ModalRoute.of(tester.element(guide));
        expect(route, isA<MaterialPageRoute<bool>>());
        expect(route!.isCurrent, isTrue);
        expect(route.opaque, isTrue);
        expect(
          find.byWidgetPredicate(
            (w) => w is ModalBarrier && (w.color?.a ?? 0) > 0,
          ),
          findsNothing,
        );
        final scaffold = find.descendant(
          of: guide,
          matching: find.byType(Scaffold),
        );
        expect(tester.getRect(scaffold), const Rect.fromLTWH(0, 0, 393, 844));
        expect(
          tester.widget<Scaffold>(scaffold).backgroundColor,
          const Color(0xFFF7F7F7),
        );
        final header = find.descendant(
          of: guide,
          matching: find.byType(CaseCreationHeader),
        );
        expect(tester.getRect(header).top, 48 + 20);
        final start = find.descendant(
          of: guide,
          matching: find.byType(FilledButton),
        );
        expect(tester.getRect(start).bottom, 844 - 24 - 38);

        if (attempt == 1) {
          await tester.binding.handlePopRoute();
        } else {
          final back = tester.widget<CaseCreationHeader>(header).onBack;
          back();
          back();
        }
        await tester.pumpAndSettle();
        expect(guide, findsNothing);
        h.expectStep(4);
        expect(h.input, 'corner');
        final area = tester.widget<AffectedAreaStep>(h.step);
        expect(area.selectedArea, 'Other');
        expect(area.issueSummary, 'Plumbing - Sink Issue');
        expect(area.locationSummary, 'Kitchen');
        h.expectNext(true);
        expect(
          find.byWidgetPredicate(
            (w) => w is ModalBarrier && (w.color?.a ?? 0) > 0,
          ),
          findsNothing,
        );
      }

      await h.next();
      final start = tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byType(EvidenceGuidePage),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed!;
      start();
      start();
      await tester.pumpAndSettle();
      expect(find.byType(EvidenceGuidePage), findsNothing);
      h.expectStep(5);
      expect(
        find.byWidgetPredicate(
          (w) => w is ModalBarrier && (w.color?.a ?? 0) > 0,
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '393x844 guide uses the Step 4 Back geometry and reference card spacing',
    (tester) async {
      final h = await CreationHarness.start(tester, direct: true);
      await h.toArea();
      await h.choose('Ceiling');
      final visual = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 33 && w.height == 33,
      );
      final before = tester.getRect(visual);
      await h.next();
      final guide = find.byType(EvidenceGuidePage);
      expect(
        tester.getRect(find.descendant(of: guide, matching: visual)),
        before,
      );
      final images = find.descendant(of: guide, matching: find.byType(Image));
      final cards = [
        for (var i = 0; i < 4; i++)
          find
              .ancestor(of: images.at(i), matching: find.byType(Container))
              .first,
      ];
      expect(tester.getRect(cards.first).top, closeTo(131, 0.01));
      expect(tester.getSize(cards.first), const Size(353, 87));
      for (var i = 1; i < 4; i++) {
        expect(
          tester.getRect(cards[i]).top - tester.getRect(cards[i - 1]).bottom,
          closeTo(8, 0.01),
        );
      }
      final button = find.descendant(
        of: guide,
        matching: find.byType(FilledButton),
      );
      expect(tester.getRect(button).left, 20);
      expect(tester.getRect(button).bottom, 806);
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
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == 'Back',
          ),
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
