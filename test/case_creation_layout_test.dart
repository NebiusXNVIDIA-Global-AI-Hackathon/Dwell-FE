import 'package:dwell/features/cases/widgets/creation/case_area_card.dart';
import 'package:dwell/features/cases/widgets/creation/case_location_card.dart';
import 'package:dwell/features/cases/widgets/creation/case_creation_header.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/case_creation_test_harness.dart';

// Retain failing assertions when production clips labels or overflows.
// Collect all stages first so one failure does not hide later layout defects.
void collectLayoutProblems(
  WidgetTester tester,
  Finder scope,
  String stage,
  List<String> problems,
) {
  Object? error;
  while ((error = tester.takeException()) != null) {
    problems.add('$stage: $error');
  }
  for (final element
      in find
          .descendant(of: scope, matching: find.byType(RichText))
          .evaluate()) {
    // Editable fields scroll horizontally; single-line hint elision is not a
    // clipped card/header label. Keyboard access is checked separately below.
    var insideField = false;
    element.visitAncestorElements((ancestor) {
      if (ancestor.widget is TextField) {
        insideField = true;
        return false;
      }
      return true;
    });
    if (insideField) continue;
    final paragraph = element.renderObject;
    if (paragraph is! RenderParagraph || !paragraph.hasSize) continue;
    final content = paragraph.text.toPlainText();
    if (content.trim().isEmpty) continue;
    final full = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
      textAlign: paragraph.textAlign,
      textHeightBehavior: paragraph.textHeightBehavior,
      strutStyle: paragraph.strutStyle,
      locale: paragraph.locale,
      textWidthBasis: paragraph.textWidthBasis,
    )..layout(maxWidth: paragraph.size.width);
    if (paragraph.didExceedMaxLines ||
        full.height > paragraph.size.height + 0.5) {
      problems.add(
        '$stage: clipped "$content" (needed height ${full.height.toStringAsFixed(1)}, available ${paragraph.size.height.toStringAsFixed(1)})',
      );
    }
    full.dispose();
  }
}

void expectFourColumns(
  WidgetTester tester,
  CreationHarness h,
  double screenWidth,
) {
  final cards = find.descendant(
    of: h.page,
    matching: find.byType(CaseAreaCard),
  );
  expect(cards, findsNWidgets(12));
  final expectedWidth = (screenWidth - 40 - 3 * 8) / 4;
  for (var i = 0; i < 4; i++) {
    expect(tester.getSize(cards.at(i)).width, closeTo(expectedWidth, 0.01));
    expect(
      tester.getTopLeft(cards.at(i)).dy,
      tester.getTopLeft(cards.first).dy,
    );
    final icon = find.descendant(
      of: cards.at(i),
      matching: find.byType(AspectRatio),
    );
    final iconSize = tester.getSize(icon);
    expect(iconSize.width, closeTo(iconSize.height, 0.01));
    expect(tester.getSize(cards.at(i)).height, greaterThan(iconSize.height));
  }
  expect(
    tester.getTopLeft(cards.at(4)).dy,
    greaterThan(tester.getTopLeft(cards.first).dy),
  );
}

void main() {
  setUpAll(loadCreationTestFonts);
  const sizes = [
    Size(320, 568),
    Size(375, 667),
    Size(393, 844),
    Size(430, 932),
  ];
  testWidgets(
    '393x844 scale 1 preserves baseline card geometry and selection size',
    (tester) async {
      final h = await CreationHarness.start(tester, direct: true);
      await h.toLocation();
      final locations = find.byType(CaseLocationCard);
      final width = (393.0 - 40 - 28) / 3;
      for (var i = 0; i < 9; i++) {
        expect(tester.getSize(locations.at(i)).width, closeTo(width, 0.01));
        expect(tester.getSize(locations.at(i)).height, closeTo(width, 0.01));
      }
      expect(
        tester.getTopLeft(locations.at(1)).dx -
            tester.getTopRight(locations.first).dx,
        closeTo(14, 0.01),
      );
      expect(
        tester.getTopLeft(locations.at(3)).dy -
            tester.getBottomLeft(locations.first).dy,
        closeTo(18, 0.01),
      );
      await h.choose('Living Room');
      expect(tester.getSize(locations.first).height, closeTo(width, 0.01));
      await h.next();
      final header = find.byType(CaseCreationHeader);
      expect(tester.getTopLeft(header).dy, 60);
      expect(tester.getSize(header).height, closeTo(59, 0.01));
      expectFourColumns(tester, h, 393);
      final cards = find.byType(CaseAreaCard);
      final before = tester.getSize(cards.first);
      final icon = find.descendant(
        of: cards.first,
        matching: find.byType(AspectRatio),
      );
      expect(tester.getSize(icon), const Size(78.25, 78.25));
      for (var i = 0; i < 12; i++) {
        final card = cards.at(i);
        final label = find.descendant(
          of: card,
          matching: find.byType(RichText),
        );
        final paragraph = tester.renderObject<RenderParagraph>(label);
        final baseline = TextPainter(
          text: paragraph.text,
          textDirection: paragraph.textDirection,
          maxLines: 3,
        )..layout(maxWidth: paragraph.size.width);
        expect(
          tester.getSize(card).height,
          closeTo(78.25 + 20 + baseline.height, 0.01),
        );
        baseline.dispose();
      }
      for (final number in ['1', '2']) {
        final circle = find
            .ancestor(
              of: find.descendant(of: h.step, matching: find.text(number)),
              matching: find.byType(Container),
            )
            .first;
        expect(tester.getSize(circle), const Size(32, 32));
      }
      await h.choose('Ceiling');
      expect(tester.getSize(cards.first), before);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in sizes) {
    for (final scale in [1.0, 1.3, 1.5]) {
      testWidgets(
        'Steps 1–4 at $size text scale $scale have readable labels and no overflow',
        (tester) async {
          final h = await CreationHarness.start(
            tester,
            size: size,
            textScale: scale,
            direct: true,
          );
          final problems = <String>[];
          collectLayoutProblems(tester, h.page, 'Step 1', problems);
          await h.choose('Plumbing');
          await h.next();
          collectLayoutProblems(tester, h.page, 'Step 2', problems);
          await h.choose('Sink Issue');
          await h.next();
          collectLayoutProblems(tester, h.page, 'Step 3', problems);
          await h.choose('Living Room');
          await h.next();
          collectLayoutProblems(tester, h.page, 'Step 4', problems);
          expectFourColumns(tester, h, size.width);
          expect(
            find.descendant(
              of: h.page,
              matching: find.byType(BottomNavigationBar),
            ),
            findsNothing,
          );
          await h.choose('Ceiling');
          final selected = find.byWidgetPredicate(
            (w) => w is CaseAreaCard && w.selected,
          );
          expect(
            find.descendant(of: selected, matching: find.byIcon(Icons.check)),
            findsOneWidget,
          );
          final material = tester.widget<Material>(
            find.descendant(of: selected, matching: find.byType(Material)),
          );
          expect(
            (material.shape! as RoundedRectangleBorder).side.color,
            const Color(0xFF007AFF),
          );
          collectLayoutProblems(tester, h.page, 'Step 4 selected', problems);
          final last = find.descendant(
            of: h.step,
            matching: find.text('Other'),
          );
          await h.tap(last);
          expect(h.field, findsOneWidget);
          await h.enter('custom corner');
          h.expectNext(true);
          expect(h.nextButton.hitTestable(), findsOneWidget);
          collectLayoutProblems(tester, h.page, 'Step 4 Other', problems);
          expect(problems, isEmpty, reason: problems.join('\n'));
        },
      );
    }
  }

  for (final location in ['Kitchen', 'Laundry Area', 'Balcony']) {
    testWidgets(
      '$location options render and remain scrollable in the real creation page',
      (tester) async {
        final h = await CreationHarness.start(tester, direct: true);
        await h.toArea(location: location);
        final problems = <String>[];
        collectLayoutProblems(tester, h.page, location, problems);
        expectFourColumns(tester, h, 393);
        final last = find.descendant(of: h.step, matching: find.text('Other'));
        await h.tap(last);
        expect(h.field, findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(problems, isEmpty, reason: problems.join('\n'));
      },
    );
  }

  for (final size in sizes) {
    testWidgets('Other inputs remain reachable with keyboard insets at $size', (
      tester,
    ) async {
      final h = await CreationHarness.start(tester, size: size, direct: true);
      final problems = <String>[];
      await h.choose('Plumbing');
      await h.next();
      await h.choose('Other');
      // Test the actual Scaffold resize behaviour, not a mocked input widget.
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pump();
      await h.enter('issue detail');
      expect(h.field.hitTestable(), findsOneWidget);
      expect(
        tester.getRect(h.field).bottom,
        lessThanOrEqualTo(size.height - 280),
      );
      collectLayoutProblems(tester, h.page, 'Step 2 keyboard', problems);
      await h.next();
      await h.choose('Other');
      await h.enter('garage');
      expect(h.field.hitTestable(), findsOneWidget);
      expect(
        tester.getRect(h.field).bottom,
        lessThanOrEqualTo(size.height - 280),
      );
      collectLayoutProblems(tester, h.page, 'Step 3 keyboard', problems);
      await h.next();
      await h.choose('Other');
      await h.enter('corner');
      expect(h.field.hitTestable(), findsOneWidget);
      expect(
        tester.getRect(h.field).bottom,
        lessThanOrEqualTo(size.height - 280),
      );
      expect(h.nextButton.hitTestable(), findsOneWidget);
      collectLayoutProblems(tester, h.page, 'Step 4 keyboard', problems);
      tester.view.resetViewInsets();
      await tester.pump();
      await h.tap(
        find.descendant(of: h.page, matching: find.byTooltip('Clear')),
      );
      expect(h.input, isEmpty);
      h.expectNext(false);
      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  }
}
