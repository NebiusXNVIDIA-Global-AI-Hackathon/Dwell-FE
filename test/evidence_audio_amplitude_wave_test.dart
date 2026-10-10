import 'package:dwell/features/cases/widgets/creation/evidence/evidence_audio_amplitude_wave.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Silence, quiet and loud input normalize and EMA smooths changes', () {
    final envelope = EvidenceAudioEnvelope();
    envelope.add(-60);
    envelope.add(-48);
    envelope.add(0);
    expect(envelope.levels[0], 0);
    expect(envelope.levels[1], closeTo(0.07, 0.00001));
    expect(envelope.levels[2], closeTo(0.3955, 0.00001));
    expect(() => envelope.levels.add(1), throwsUnsupportedError);
    envelope.clear();
    expect(envelope.levels, isEmpty);
    envelope.add(10);
    expect(envelope.levels, [1]);
    envelope.clear();
    envelope.add(double.nan);
    expect(envelope.levels, [0]);
    envelope.add(double.negativeInfinity);
    expect(envelope.levels, [0, 0]);
  });
  Future<void> show(
    WidgetTester tester,
    List<double> levels, {
    double width = 353,
    bool animate = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: width,
            height: 170,
            child: EvidenceAudioAmplitudeWave(levels: levels, animate: animate),
          ),
        ),
      ),
    );
  }

  Finder bar(int i) => find.byKey(ValueKey('amplitude-$i'));
  Color color(WidgetTester tester, int i) =>
      (tester.widget<Container>(bar(i)).decoration as BoxDecoration).color!;
  testWidgets(
    '15 fixed centered rounded bars respond to silence, quiet and loud input',
    (tester) async {
      await show(tester, []);
      final center = tester.getCenter(bar(7));
      for (var i = 0; i < 15; i++) {
        expect(tester.getSize(bar(i)).height, 6);
        expect(color(tester, i), const Color(0xFFE5E5E5));
      }
      expect(
        tester.getTopLeft(bar(14)).dx + 6 - tester.getTopLeft(bar(0)).dx,
        230,
      );
      await show(tester, [0.2]);
      expect(tester.getSize(bar(7)).height, closeTo(38.8, 0.01));
      expect(color(tester, 0), const Color(0xFF666666));
      expect(color(tester, 3), const Color(0xFFE5E5E5));
      final quietHeight = tester.getSize(bar(3)).height;
      await show(tester, [0.2, 1]);
      expect(tester.getSize(bar(7)).height, 170);
      expect(tester.getSize(bar(3)).height, greaterThan(quietHeight));
      expect(color(tester, 13), const Color(0xFF666666));
      expect(color(tester, 14), const Color(0xFFE5E5E5));
      expect(tester.getCenter(bar(7)), center);
      for (var i = 0; i < 15; i++) {
        expect(tester.getCenter(bar(i)).dy, center.dy);
        expect(
          tester.getSize(bar(i)).height,
          tester.getSize(bar(14 - i)).height,
        );
        expect(
          (tester.widget<Container>(bar(i)).decoration as BoxDecoration)
              .borderRadius,
          BorderRadius.circular(6),
        );
      }
    },
  );
  testWidgets(
    'Only latest input controls shape; history length never scrolls positions',
    (tester) async {
      await show(tester, [0.5]);
      final positions = List.generate(15, (i) => tester.getCenter(bar(i)));
      final heights = List.generate(15, (i) => tester.getSize(bar(i)).height);
      await show(tester, [...List.filled(2000, 1.0), 0.5]);
      expect(find.byType(AnimatedPositioned), findsNothing);
      for (var i = 0; i < 15; i++) {
        expect(tester.getCenter(bar(i)), positions[i]);
        expect(tester.getSize(bar(i)).height, heights[i]);
      }
    },
  );
  testWidgets(
    'Height and color interpolate only on measurements and freeze afterward',
    (tester) async {
      await show(tester, [0], animate: true);
      final position = tester.getCenter(bar(7));
      await show(tester, [1], animate: true);
      await tester.pump(const Duration(milliseconds: 70));
      expect(tester.getSize(bar(7)).height, greaterThan(6));
      expect(tester.getSize(bar(7)).height, lessThan(170));
      expect(color(tester, 13), isNot(const Color(0xFF666666)));
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.getSize(bar(7)).height, 170);
      expect(tester.getCenter(bar(7)), position);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.getSize(bar(7)).height, 170);
      await show(tester, [0.3], animate: false);
      final fixed = tester.getSize(bar(7));
      await tester.pump(const Duration(seconds: 3));
      expect(tester.getSize(bar(7)), fixed);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Narrow widths keep all bars centered without overflow; reset is silent',
    (tester) async {
      await show(tester, [1], width: 100);
      expect(tester.getSize(bar(0)).width, lessThan(6));
      expect(tester.getCenter(bar(7)).dx, 400);
      await show(tester, [], width: 4);
      expect(tester.getSize(bar(7)).height, 6);
      expect(tester.takeException(), isNull);
    },
  );
}
