import 'package:camera/camera.dart';
import 'package:dwell/features/cases/controllers/evidence_controller.dart';
import 'package:dwell/features/cases/controllers/mock_evidence_check_controller.dart';
import 'package:dwell/features/cases/models/evidence_model.dart';
import 'package:dwell/features/cases/widgets/creation/steps/evidence_step.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/case_creation_test_harness.dart';

Future<EvidenceModel> checkPhoto(WidgetTester tester) async {
  final data = (await rootBundle.load(
    'assets/images/evidence_guide/overall_view.png',
  )).buffer.asUint8List();
  return (await tester.runAsync(
    () => EvidenceModel.fromFile(XFile.fromData(data, name: 'photo.png')),
  ))!;
}

Future<CreationHarness> checkPage(
  WidgetTester tester, {
  Size size = const Size(393, 844),
  double scale = 1,
}) async {
  final h = await CreationHarness.start(
    tester,
    direct: true,
    size: size,
    textScale: scale,
  );
  await h.toArea();
  await h.choose('Ceiling');
  await h.next();
  await h.tap(find.text('Start Adding Evidence'));
  return h;
}

void main() {
  setUpAll(loadCreationTestFonts);
  testWidgets(
    'Production mode never runs the mock or marks evidence completed',
    (tester) async {
      final evidence = EvidenceController();
      final demo = MockEvidenceCheckController(evidence, demoEnabled: false);
      evidence.add(await checkPhoto(tester));
      expect(demo.buttonEnabled, false);
      demo.start();
      await tester.pump(const Duration(seconds: 4));
      expect(demo.status, MockEvidenceCheckStatus.idle);
      expect(demo.completedCount, 0);
      demo.dispose();
      evidence.dispose();
    },
  );
  testWidgets(
    'Checklist appears once with evidence and disappears after deleting all',
    (tester) async {
      final h = await checkPage(tester);
      final step = tester.widget<EvidenceStep>(find.byType(EvidenceStep));
      void expectChecklist(bool visible) {
        for (var i = 0; i < evidenceCheckLabels.length; i++) {
          expect(
            find.text(evidenceCheckLabels[i]),
            visible ? findsOneWidget : findsNothing,
          );
          expect(
            find.byKey(ValueKey('evidence-check-idle-$i')),
            visible ? findsOneWidget : findsNothing,
          );
        }
        expect(find.text('Demo check · No AI analysis'), findsNothing);
      }

      expectChecklist(false);
      h.expectNext(false);
      final a = await checkPhoto(tester), b = await checkPhoto(tester);
      step.evidence!.add(a);
      await tester.pumpAndSettle();
      expectChecklist(true);
      h.expectNext(true);
      step.evidence!.add(b);
      await tester.pumpAndSettle();
      expectChecklist(true);
      await tester.tap(h.nextButton);
      await tester.pump(mockEvidenceCheckInterval);
      expect(step.mockCheck!.completedCount, 1);
      step.evidence!.remove(a.id);
      await tester.pumpAndSettle();
      expectChecklist(true);
      expect(step.mockCheck!.status, MockEvidenceCheckStatus.idle);
      step.mockCheck!.start();
      await tester.pump();
      step.evidence!.remove(b.id);
      await tester.pumpAndSettle();
      expectChecklist(false);
      h.expectNext(false);
      await tester.pump(const Duration(seconds: 4));
      expect(step.mockCheck!.completedCount, 0);
      expect(find.byKey(const ValueKey('evidence-add')), findsOneWidget);
      step.evidence!.add(await checkPhoto(tester));
      await tester.pumpAndSettle();
      expectChecklist(true);
      h.expectNext(true);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Demo runs in order, blocks duplicate calls and never mutates evidence',
    (tester) async {
      final evidence = EvidenceController();
      final demo = MockEvidenceCheckController(evidence);
      expect(demo.buttonEnabled, false);
      demo.start();
      expect(demo.status, MockEvidenceCheckStatus.idle);
      final photo = await checkPhoto(tester);
      evidence.add(photo);
      expect(demo.buttonEnabled, true);
      final bytes = List<int>.of(photo.bytes);
      demo.start();
      demo.start();
      expect(demo.status, MockEvidenceCheckStatus.checking);
      expect(demo.currentIndex, 0);
      await tester.pump(const Duration(milliseconds: 699));
      expect(demo.completedCount, 0);
      await tester.pump(const Duration(milliseconds: 1));
      expect(demo.completedCount, 1);
      expect(demo.currentIndex, 1);
      demo.start();
      await tester.pump(mockEvidenceCheckInterval);
      expect(demo.completedCount, 2);
      expect(demo.currentIndex, 2);
      await tester.pump(mockEvidenceCheckInterval);
      expect(demo.status, MockEvidenceCheckStatus.completed);
      expect(demo.completedCount, 3);
      expect(demo.currentIndex, isNull);
      expect(demo.buttonLabel, 'Next');
      expect(demo.buttonEnabled, true);
      expect(evidence.items, [photo]);
      expect(photo.bytes, bytes);
      expect(photo.isDisposed, false);
      expect(photo.audioLevels, isEmpty);
      demo.start();
      expect(demo.currentIndex, 0);
      expect(demo.completedCount, 0);
      demo.dispose();
      await tester.pump(const Duration(seconds: 5));
      expect(demo.status, MockEvidenceCheckStatus.idle);
      evidence.dispose();
    },
  );
  testWidgets(
    'Membership changes invalidate previous timer; selection does not reset',
    (tester) async {
      final evidence = EvidenceController();
      final demo = MockEvidenceCheckController(evidence);
      final a = await checkPhoto(tester), b = await checkPhoto(tester);
      evidence.add(a);
      evidence.add(b);
      demo.start();
      await tester.pump(mockEvidenceCheckInterval);
      evidence.select(a.id);
      expect(demo.completedCount, 1);
      evidence.remove(b.id);
      expect(demo.status, MockEvidenceCheckStatus.idle);
      expect(demo.completedCount, 0);
      await tester.pump(const Duration(milliseconds: 500));
      demo.start();
      await tester.pump(const Duration(milliseconds: 200));
      expect(demo.completedCount, 0);
      await tester.pump(const Duration(milliseconds: 500));
      expect(demo.completedCount, 1);
      demo.cancelChecking();
      await tester.pump(const Duration(seconds: 3));
      expect(demo.completedCount, 0);
      demo.start();
      await tester.pump(const Duration(milliseconds: 2100));
      expect(demo.status, MockEvidenceCheckStatus.completed);
      evidence.add(await checkPhoto(tester));
      expect(demo.status, MockEvidenceCheckStatus.idle);
      evidence.remove(a.id);
      demo.dispose();
      evidence.dispose();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Check → Checking → Next is read-only, announces demo and keeps Step 5',
    (tester) async {
      final h = await checkPage(tester);
      h.expectNext(false);
      final step = tester.widget<EvidenceStep>(find.byType(EvidenceStep));
      final photo = await checkPhoto(tester);
      step.evidence!.add(photo);
      await tester.pumpAndSettle();
      h.expectNext(true);
      expect(find.text('Demo check · No AI analysis'), findsNothing);
      await tester.ensureVisible(
        find.byKey(const ValueKey('evidence-check-item-0')),
      );
      await tester.tap(find.byKey(const ValueKey('evidence-check-item-0')));
      await tester.pump();
      expect(step.mockCheck!.status, MockEvidenceCheckStatus.idle);
      await tester.tap(h.nextButton);
      await tester.pump();
      h.expectNext(false);
      expect(find.text('Checking your evidence...'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('evidence-check-loading-0')),
        findsOneWidget,
      );
      await tester.pump(mockEvidenceCheckInterval);
      expect(step.mockCheck!.completedCount, 1);
      await tester.pump(mockEvidenceCheckInterval);
      expect(step.mockCheck!.completedCount, 2);
      await tester.pump(mockEvidenceCheckInterval);
      await tester.pump(evidenceCheckTransitionDuration);
      expect(find.text('Next'), findsOneWidget);
      h.expectNext(true);
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(ValueKey('evidence-check-done-$i')), findsOneWidget);
      }
      await h.next();
      h.expectStep(5);
      expect(find.textContaining('Coming soon'), findsOneWidget);
      step.evidence!.remove(photo.id);
      await tester.pumpAndSettle();
      h.expectNext(false);
      expect(find.text('Check'), findsOneWidget);
      expect(step.mockCheck!.completedCount, 0);
    },
  );
  testWidgets('Background and page disposal cancel an active demo safely', (
    tester,
  ) async {
    final h = await checkPage(tester);
    final step = tester.widget<EvidenceStep>(find.byType(EvidenceStep));
    step.evidence!.add(await checkPhoto(tester));
    await tester.pumpAndSettle();
    await tester.tap(h.nextButton);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(step.mockCheck!.status, MockEvidenceCheckStatus.idle);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    step.mockCheck!.start();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, false);
  });
  for (final size in [const Size(320, 568), const Size(393, 844)]) {
    testWidgets('Checklist wraps at $size with 2× text and pinned button', (
      tester,
    ) async {
      final h = await checkPage(tester, size: size);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      await tester.pumpAndSettle();
      final step = tester.widget<EvidenceStep>(find.byType(EvidenceStep));
      step.evidence!.add(await checkPhoto(tester));
      await tester.pumpAndSettle();
      final bottom = tester.getRect(h.nextButton);
      await tester.ensureVisible(
        find.byKey(const ValueKey('evidence-check-item-2')),
      );
      await tester.pumpAndSettle();
      await tester.tap(h.nextButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pumpAndSettle();
      expect(tester.getRect(h.nextButton), bottom);
      expect(tester.takeException(), isNull);
    });
  }
}
