import 'package:dwell/features/cases/widgets/creation/case_area_card.dart';
import 'package:dwell/features/cases/widgets/creation/case_creation_header.dart';
import 'package:dwell/features/cases/widgets/creation/case_creation_bottom.dart';
import 'package:dwell/features/cases/widgets/creation/steps/affected_area_step.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    '393x844: four columns, complete labels, selection, edits and scroll',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fonts = FontLoader('Pretendard Variable')
        ..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'));
      await fonts.load();
      final roboto = FontLoader('Roboto')
        ..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'));
      await roboto.load();
      final materialIcons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await materialIcons.load();
      var issueEdits = 0;
      var locationEdits = 0;
      String? selection;
      final boundary = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Pretendard Variable'),
          home: RepaintBoundary(
            key: boundary,
            child: Scaffold(
              backgroundColor: const Color(0xFFF7F7F7),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
                  child: Column(
                    children: [
                      CaseCreationHeader(
                        title: 'Affected Area',
                        currentStep: 4,
                        totalSteps: 7,
                        onBack: () {},
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: AffectedAreaStep(
                          issueSummary: 'Water & Flooding - Water Leak',
                          location: 'Living Room',
                          locationSummary: 'Living Room',
                          selectedArea: 'Ceiling',
                          otherText: '',
                          onChanged: (value) => selection = value,
                          onEdit: () => issueEdits++,
                          onEditLocation: () => locationEdits++,
                          onOtherChanged: (_) {},
                        ),
                      ),
                      const SizedBox(height: 16),
                      CaseCreationBottom(enabled: true, onNext: () {}),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('What exactly is the issue'), findsOneWidget);
      expect(find.text('Select affected area'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('steps 4 of 7'), findsOneWidget);
      final cards = find.byType(CaseAreaCard);
      expect(cards, findsNWidgets(12));
      for (var i = 0; i < 4; i++) {
        expect(
          tester.getTopLeft(cards.at(i)).dy,
          tester.getTopLeft(cards.first).dy,
        );
        expect(tester.getSize(cards.at(i)).width, closeTo(82.25, 0.01));
      }
      expect(
        tester.getTopLeft(cards.at(4)).dy,
        greaterThan(tester.getTopLeft(cards.first).dy),
      );
      final icon = find.descendant(
        of: cards.first,
        matching: find.byType(AspectRatio),
      );
      final size = tester.getSize(icon);
      expect(size.width, size.height);
      expect(
        find.descendant(of: cards.first, matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
      final material = tester.widget<Material>(
        find.descendant(of: cards.first, matching: find.byType(Material)),
      );
      expect(
        (material.shape! as RoundedRectangleBorder).side.color,
        const Color(0xFF007AFF),
      );
      final label = tester.renderObject<RenderParagraph>(
        find.text('Electrical Outlet / Fixture'),
      );
      final painter = TextPainter(
        text: label.text,
        textDirection: TextDirection.ltr,
        maxLines: 3,
      )..layout(maxWidth: label.size.width);
      expect(painter.computeLineMetrics().length, 3);
      painter.dispose();
      expect(label.didExceedMaxLines, isFalse);
      await tester.tap(find.text('Edit').first);
      await tester.tap(find.text('Edit').last);
      expect(issueEdits, 1);
      expect(locationEdits, 1);
      await tester.ensureVisible(cards.last);
      await tester.pumpAndSettle();
      await tester.tap(cards.last);
      expect(selection, 'Other');
      expect(tester.takeException(), isNull);
    },
  );
}
