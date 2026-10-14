import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dwell/features/cases/controllers/mock_evidence_check_controller.dart';
import 'package:dwell/features/cases/models/case_draft.dart';
import 'package:dwell/features/cases/pages/case_creation_page.dart';
import 'package:dwell/features/cases/widgets/creation/steps/description_step.dart';
import 'package:dwell/features/cases/widgets/creation/steps/evidence_step.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'evidence_check_test.dart' show checkPhoto;
import 'helpers/case_creation_test_harness.dart';

Future<CreationHarness> openDescription(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  double topInset = 0,
  CaseCreationCompletion? onComplete,
  bool useAnalysisRoute = false,
}) async {
  final h = await CreationHarness.start(
    tester,
    direct: true,
    size: size,
    textScale: scale,
    onComplete: useAnalysisRoute ? null : onComplete ?? (_, _) async {},
  );
  tester.view.padding = FakeViewPadding(top: topInset);
  tester.view.viewPadding = FakeViewPadding(top: topInset);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
  await h.toArea();
  await h.choose('Ceiling');
  await h.next();
  await h.tap(find.text('Start Adding Evidence'));
  final step = tester.widget<EvidenceStep>(find.byType(EvidenceStep));
  step.evidence!.add(await checkPhoto(tester));
  await tester.pumpAndSettle();
  await h.next();
  await tester.pump(mockEvidenceCheckInterval * 3);
  await tester.pumpAndSettle();
  await h.next();
  h.expectStep(6);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  await tester.pumpAndSettle();
  return h;
}

void main() {
  setUpAll(() async {
    await loadCreationTestFonts();
    await (FontLoader('packages/lucide_icons_flutter/Lucide')..addFont(
          rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
        ))
        .load();
  });
  if (const bool.fromEnvironment('DWELL_DESCRIPTION_PREVIEW')) {
    testWidgets('Description design previews', (tester) async {
      final h = await openDescription(tester);
      tester.view.padding = const FakeViewPadding(top: 44);
      addTearDown(tester.view.resetPadding);
      await tester.pumpAndSettle();
      final directory = Directory(
        '${Directory.systemTemp.path}/dwell-diagnostics',
      );
      Future<void> capture(String name) async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary).first,
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          await File('${directory.path}/step6-$name.png')
              .writeAsBytes(data!.buffer.asUint8List());
        });
      }

      await capture('empty');
      await h.enter(
        'Water is leaking from the ceiling above the shower. The stain has gotten bigger since last week.',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await capture('filled');
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'Empty, focused, filled and cleared description stay synchronized',
    (tester) async {
      final h = await openDescription(tester);
      h.expectNext(false);
      expect(find.text('0/500'), findsOneWidget);
      expect(find.byKey(const ValueKey('description-clear')), findsNothing);
      final box = find.byKey(const ValueKey('description-input-box'));
      expect(tester.getSize(box).height, 138);
      await h.enter(' \n ');
      h.expectNext(false);
      await h.enter('Water is leaking.');
      h.expectNext(true);
      expect(find.text('17/500'), findsOneWidget);
      expect(
        tester
            .widget<DescriptionStep>(find.byType(DescriptionStep))
            .description,
        h.input,
      );
      await tester.pumpAndSettle();
      expect(
        (tester.widget<AnimatedContainer>(box).decoration! as BoxDecoration)
            .border,
        Border.all(color: const Color(0xFF0066FF)),
      );
      await h.tap(find.byKey(const ValueKey('description-clear')));
      expect(h.input, '');
      expect(find.text('0/500'), findsOneWidget);
      h.expectNext(false);
      await h.enter(List.filled(501, 'a').join());
      expect(h.input.length, 500);
      expect(find.text('500/500'), findsOneWidget);
      expect(tester.getSize(box).height, 138);
      await h.tap(h.headerBack);
      h.expectStep(5);
      expect(
        tester
            .widget<EvidenceStep>(find.byType(EvidenceStep))
            .evidence!
            .items
            .length,
        1,
      );
      await h.next();
      h.expectStep(6);
      expect(h.input.length, 500);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Skip underlines only while pressed, never on hover or focus, without overlays',
    (tester) async {
      await openDescription(tester);
      final skip = find.byKey(const ValueKey('description-skip'));
      final label = find.text('skip this step');
      await tester.ensureVisible(skip);
      await tester.pumpAndSettle();
      TextStyle labelStyle() =>
          DefaultTextStyle.of(tester.element(label)).style;
      expect(labelStyle().decoration, TextDecoration.none);
      expect(labelStyle().color, const Color(0xFF5E5E5E));
      expect(labelStyle().fontWeight, FontWeight.w600);
      final style = tester.widget<TextButton>(skip).style!;
      for (final states in [
        <WidgetState>{},
        {WidgetState.hovered},
        {WidgetState.pressed},
      ]) {
        expect(style.backgroundColor!.resolve(states), Colors.transparent);
        expect(style.overlayColor!.resolve(states), Colors.transparent);
      }
      expect(style.splashFactory, NoSplash.splashFactory);
      expect(
        style.textStyle!.resolve({WidgetState.focused})!.decoration,
        TextDecoration.none,
      );
      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(skip));
      await tester.pumpAndSettle();
      expect(labelStyle().decoration, TextDecoration.none);
      await mouse.down(tester.getCenter(skip));
      await tester.pumpAndSettle();
      expect(labelStyle().decoration, TextDecoration.underline);
      await mouse.up();
      await tester.pumpAndSettle();
      expect(labelStyle().decoration, TextDecoration.none);
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(labelStyle().decoration, TextDecoration.none);
      await mouse.removePointer();
      final touch = await tester.startGesture(tester.getCenter(skip));
      await tester.pumpAndSettle();
      expect(labelStyle().decoration, TextDecoration.underline);
      await touch.up();
      await tester.pumpAndSettle();
      expect(labelStyle().decoration, TextDecoration.none);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Shared completion callback preserves Submit and omits Skip data; blocks duplicate calls',
    (tester) async {
      final received = <CaseDraftView>[];
      final pending = Completer<void>();
      final h = await openDescription(
        tester,
        onComplete: (draft, evidence) async {
          received.add(draft);
          expect(evidence.length, 1);
          if (received.length == 1) await pending.future;
        },
      );
      await h.enter('  Description  ');
      await tester.ensureVisible(h.nextButton);
      await tester.tap(h.nextButton);
      await tester.pump();
      h.expectNext(false);
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('description-skip')))
            .onPressed,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      h.expectStep(6);
      pending.complete();
      await tester.pumpAndSettle();
      expect(received.single.description, '  Description  ');
      await h.tap(find.byKey(const ValueKey('description-skip')));
      expect(received.last.description, '');
      expect(h.input, '  Description  ');
      h.expectStep(6);
      await h.tap(find.byKey(const ValueKey('description-clear')));
      await h.tap(find.byKey(const ValueKey('description-skip')));
      expect(received.length, 3);
      expect(received.last.description, '');
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(1280, 800),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Description scrolls without overflow at $size scale $scale with keyboard',
        (tester) async {
          final h = await openDescription(tester, size: size, scale: scale);
          await h.enter('Keyboard description');
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.byKey(const ValueKey('description-skip')),
          );
          await tester.pumpAndSettle();
          expect(
            tester
                .getRect(find.byKey(const ValueKey('description-skip')))
                .bottom,
            lessThanOrEqualTo(size.height - 300),
          );
          expect(tester.takeException(), isNull);
          tester.view.resetViewInsets();
          tester.platformDispatcher.textScaleFactorTestValue = 1;
          await tester.pumpAndSettle();
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          h.expectStep(5);
        },
      );
    }
  }
}
