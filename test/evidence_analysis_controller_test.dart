import 'package:dwell/features/cases/controllers/evidence_analysis_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Mock progresses in order once, holds completion and stops on dispose',
    (tester) async {
      final runner = MockEvidenceAnalysisController(
        interval: const Duration(milliseconds: 100),
      );
      expect(runner.stateAt(0), AnalysisProgressState.waiting);
      var changes = 0;
      runner.addListener(() => changes++);
      runner.start();
      runner.start();
      expect(changes, 1);
      for (var step = 0; step < 5; step++) {
        expect(runner.stateAt(step), AnalysisProgressState.running);
        if (step < 4) {
          expect(runner.stateAt(step + 1), AnalysisProgressState.waiting);
        }
        await tester.pump(const Duration(milliseconds: 100));
        expect(runner.completedCount, step + 1);
        expect(runner.stateAt(step), AnalysisProgressState.completed);
      }
      expect(runner.isComplete, true);
      expect(runner.isRunning, false);
      runner.start();
      await tester.pump(const Duration(seconds: 10));
      expect(changes, 6);
      runner.dispose();
      await tester.pump(const Duration(seconds: 10));
      expect(changes, 6);
    },
  );

  testWidgets(
    'Cancellation and early disposal prevent late ticks and duplicate starts',
    (tester) async {
      final runner = MockEvidenceAnalysisController();
      runner.start();
      await tester.pump(const Duration(milliseconds: 900));
      runner.cancel();
      runner.start();
      await tester.pump(const Duration(seconds: 10));
      expect(runner.completedCount, 1);
      runner.dispose();
      final early = MockEvidenceAnalysisController();
      early.start();
      early.dispose();
      early.start();
      await tester.pump(const Duration(seconds: 10));
      expect(early.completedCount, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
