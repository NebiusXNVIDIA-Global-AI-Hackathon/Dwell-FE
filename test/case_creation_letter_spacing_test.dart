import 'package:dwell/core/theme.dart';
import 'package:dwell/features/cases/widgets/creation/dialogs/safety_notice_dialog.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'case_creation_layout_test.dart' show collectLayoutProblems;
import 'helpers/case_creation_test_harness.dart';

List<TextStyle?> styles(TextTheme t) => [
  t.displayLarge,
  t.displayMedium,
  t.displaySmall,
  t.headlineLarge,
  t.headlineMedium,
  t.headlineSmall,
  t.titleLarge,
  t.titleMedium,
  t.titleSmall,
  t.bodyLarge,
  t.bodyMedium,
  t.bodySmall,
  t.labelLarge,
  t.labelMedium,
  t.labelSmall,
];
void expectFontSpacing(WidgetTester tester) {
  for (final e in find.byType(RichText).evaluate()) {
    final r = e.renderObject;
    if (r is! RenderParagraph) continue;
    void check(InlineSpan span) {
      expect(span.style?.letterSpacing, isNull, reason: span.toPlainText());
    }

    check(r.text);
    r.text.visitChildren((span) {
      check(span);
      return true;
    });
  }
}

void main() {
  setUpAll(loadCreationTestFonts);
  for (final brightness in Brightness.values) {
    for (final category in ScriptCategory.values) {
      test('Font spacing only changes tracking at $brightness / $category', () {
        final original = ThemeData(
          fontFamily: 'Pretendard Variable',
          scaffoldBackgroundColor: brightness == Brightness.light
              ? const Color(0xFFF8F8F8)
              : null,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF243B53),
            brightness: brightness,
          ),
        );
        final changed = buildTheme(brightness);
        final before = ThemeData.localize(
          original,
          original.typography.geometryThemeFor(category),
        );
        final after = ThemeData.localize(
          changed,
          changed.typography.geometryThemeFor(category),
        );
        final expected = [
          ...styles(before.textTheme),
          ...styles(before.primaryTextTheme),
        ];
        final actual = [
          ...styles(after.textTheme),
          ...styles(after.primaryTextTheme),
        ];
        for (var i = 0; i < actual.length; i++) {
          expect(actual[i]!.letterSpacing, isNull);
          expect(
            actual[i]!.copyWith(letterSpacing: expected[i]!.letterSpacing),
            expected[i],
          );
        }
        expect(after.colorScheme, before.colorScheme);
        expect(after.scaffoldBackgroundColor, before.scaffoldBackgroundColor);
      });
    }
  }
  for (final size in [
    const Size(320, 568),
    const Size(375, 667),
    const Size(393, 844),
    const Size(430, 932),
  ]) {
    for (final scale in [1.0, 1.3, 1.5]) {
      testWidgets(
        'Rendered Steps 1–4 and dialogs use font spacing at $size scale $scale',
        (tester) async {
          final h = await CreationHarness.start(
            tester,
            size: size,
            textScale: scale,
          );
          final problems = <String>[];
          expectFontSpacing(tester);
          collectLayoutProblems(tester, h.page, 'Step 1', problems);
          await h.choose('Plumbing');
          await h.next();
          await h.choose('Other');
          await h.enter(' leak ');
          expectFontSpacing(tester);
          collectLayoutProblems(tester, h.page, 'Step 2', problems);
          await h.next();
          await h.choose('Other');
          await h.enter(' garage ');
          expectFontSpacing(tester);
          collectLayoutProblems(tester, h.page, 'Step 3', problems);
          await h.next();
          await h.choose('Other');
          await h.enter(' corner ');
          expectFontSpacing(tester);
          collectLayoutProblems(tester, h.page, 'Step 4', problems);
          await h.tap(h.headerBack);
          expectFontSpacing(tester);
          collectLayoutProblems(tester, find.byType(Dialog), 'Exit', problems);
          await h.tap(find.widgetWithText(TextButton, 'Stay'));
          await h.editIssue();
          await h.choose('Gas');
          await h.next();
          expect(find.byType(SafetyNoticeDialog), findsOneWidget);
          expectFontSpacing(tester);
          collectLayoutProblems(
            tester,
            find.byType(Dialog),
            'Safety',
            problems,
          );
          expect(problems, isEmpty, reason: problems.join('\n'));
        },
      );
    }
  }
}
