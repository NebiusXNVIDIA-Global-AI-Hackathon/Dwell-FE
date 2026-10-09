import 'dart:async';

import 'package:camera/camera.dart';
import 'package:dwell/core/theme.dart';
import 'package:dwell/features/cases/controllers/evidence_controller.dart';
import 'package:dwell/features/cases/models/evidence_model.dart';
import 'package:dwell/features/cases/pages/evidence/evidence_camera_page.dart';
import 'package:dwell/features/cases/services/evidence_camera.dart';
import 'package:dwell/features/cases/widgets/creation/steps/evidence_step.dart';
import 'package:dwell/features/cases/widgets/creation/evidence/evidence_add_sheet.dart';
import 'package:flutter/services.dart';
import 'package:dwell/features/cases/widgets/creation/case_creation_bottom.dart';
import 'package:dwell/features/cases/widgets/creation/steps/affected_area_step.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'case_creation_layout_test.dart' show collectLayoutProblems;
import 'helpers/case_creation_test_harness.dart';

late Uint8List photoBytes;
XFile photoFile() => XFile.fromData(
  photoBytes,
  name: 'capture.png',
  path: 'capture.png',
  mimeType: 'image/png',
);

class FakeCamera implements EvidenceCamera {
  Completer<void>? initGate;
  Completer<XFile>? captureGate;
  Object? initError;
  Object? captureError;
  Object? disposeError;
  int captures = 0;
  int initializes = 0;
  int disposes = 0;
  @override
  Future<void> initialize() async {
    initializes++;
    await initGate?.future;
    if (initError != null) throw initError!;
  }

  @override
  Widget buildPreview({Widget? overlay}) => AspectRatio(
    aspectRatio: 3 / 4,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(key: ValueKey('fake-preview'), color: Colors.grey),
        ?overlay,
      ],
    ),
  );
  @override
  Future<XFile> takePicture() async {
    captures++;
    if (captureError != null) throw captureError!;
    return captureGate != null ? await captureGate!.future : photoFile();
  }

  @override
  Future<void> dispose() async {
    disposes++;
    if (disposeError != null) throw disposeError!;
  }
}

Finder get shutter => find.byKey(const ValueKey('camera-shutter'));
Future<void> openCamera(
  WidgetTester tester,
  EvidenceCamera Function() factory, {
  Size size = const Size(393, 844),
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EvidenceCameraPage(cameraFactory: factory),
            ),
          ),
          child: const Text('Open camera'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open camera'));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

Future<void> completeCapture(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.tap(shutter);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await loadCreationTestFonts();
    photoBytes = (await rootBundle.load(
      'assets/images/evidence_guide/overall_view.png',
    )).buffer.asUint8List();
  });
  testWidgets('Loading, preview, guide, cancel and resource release', (
    tester,
  ) async {
    final camera = FakeCamera()..initGate = Completer<void>();
    await openCamera(tester, () => camera);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<FilledButton>(shutter).onPressed, isNull);
    camera.initGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.byKey(const ValueKey('fake-preview')), findsOneWidget);
    expect(
      find.text('Make sure the problem area is clearly in view'),
      findsOneWidget,
    );
    expect(tester.getSize(shutter), const Size(72, 72));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(camera.disposes, 1);
    expect(camera.captures, 0);
    expect(tester.takeException(), isNull);
  });
  for (final code in [
    'CameraAccessDenied',
    'NoCamera',
    'InitializationFailed',
    'permissionDenied',
  ]) {
    testWidgets(
      'Camera error CODE has retry and Back'.replaceAll('CODE', code),
      (tester) async {
        final bad = FakeCamera()..initError = CameraException(code, 'error');
        final good = FakeCamera();
        var calls = 0;
        await openCamera(tester, () => calls++ == 0 ? bad : good);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(tester.widget<FilledButton>(shutter).onPressed, isNull);
        expect(find.text('Retry'), findsOneWidget);
        expect(bad.disposes, 1);
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(good.initializes, 1);
        expect(tester.widget<FilledButton>(shutter).onPressed, isNotNull);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(good.disposes, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Initialization cleanup failure still offers retry', (
    tester,
  ) async {
    final bad = FakeCamera()
      ..initError = CameraException('CameraAccessDenied', 'denied')
      ..disposeError = StateError('cleanup failed');
    final good = FakeCamera();
    var calls = 0;
    await openCamera(tester, () => calls++ == 0 ? bad : good);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(good.initializes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Duplicate shutter taps capture once; success returns a genuine photo',
    (tester) async {
      final fake = FakeCamera()..captureGate = Completer<XFile>();
      EvidenceModel? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<EvidenceModel>(
                  MaterialPageRoute(
                    builder: (_) =>
                        EvidenceCameraPage(cameraFactory: () => fake),
                  ),
                );
              },
              child: const Text('Open camera'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open camera'));
      await tester.pumpAndSettle();
      await tester.tap(shutter);
      await tester.pump();
      await tester.tap(shutter);
      await tester.pump();
      expect(fake.captures, 1);
      expect(tester.widget<FilledButton>(shutter).onPressed, isNull);
      await tester.runAsync(() async {
        fake.captureGate!.complete(photoFile());
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.mimeType, 'image/png');
      expect(result!.fileName, 'capture.png');
      expect(result!.bytes, orderedEquals(photoBytes));
      expect(fake.disposes, 1);
      expect(find.byType(EvidenceCameraPage), findsNothing);
    },
  );
  testWidgets(
    'Capture failure stays usable and retry does not fabricate evidence',
    (tester) async {
      final fake = FakeCamera()..captureError = StateError('failure');
      await openCamera(tester, () => fake);
      await completeCapture(tester);
      expect(
        find.text('The photo could not be captured. Please try again.'),
        findsOneWidget,
      );
      expect(find.byType(EvidenceCameraPage), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      fake.captureError = null;
      await completeCapture(tester);
      expect(fake.captures, 2);
      expect(fake.disposes, 1);
    },
  );
  testWidgets('Back while capture is pending ignores late results', (
    tester,
  ) async {
    final fake = FakeCamera()..captureGate = Completer<XFile>();
    await openCamera(tester, () => fake);
    await tester.tap(shutter);
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      fake.captureGate!.complete(photoFile());
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.byType(EvidenceCameraPage), findsNothing);
    expect(fake.disposes, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Late initialization after exit releases camera without setState',
    (tester) async {
      final fake = FakeCamera()..initGate = Completer<void>();
      await openCamera(tester, () => fake);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      fake.initGate!.complete();
      await tester.pumpAndSettle();
      expect(fake.disposes, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Background releases camera; resume initializes a fresh session',
    (tester) async {
      final first = FakeCamera();
      final second = FakeCamera();
      var calls = 0;
      await openCamera(tester, () => calls++ == 0 ? first : second);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(first.disposes, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(second.initializes, 1);
      expect(find.byKey(const ValueKey('fake-preview')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(second.disposes, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Real Step 5 capture flow adds, selects, deletes and preserves inputs',
    (tester) async {
      final cameras = <FakeCamera>[];
      final h = await CreationHarness.start(
        tester,
        direct: true,
        capturePhoto: (context) {
          final fake = FakeCamera();
          cameras.add(fake);
          return Navigator.of(context).push<EvidenceModel>(
            MaterialPageRoute(
              builder: (_) => EvidenceCameraPage(cameraFactory: () => fake),
            ),
          );
        },
      );
      await h.toArea();
      await h.choose('Other');
      await h.enter('corner');
      final originalArea = tester.widget<AffectedAreaStep>(h.step);
      await h.next();
      await h.tap(find.text('Start Adding Evidence'));
      for (var i = 0; i < 2; i++) {
        await h.tap(find.byKey(const ValueKey('evidence-add')));
        await h.tap(find.byKey(const ValueKey(EvidenceSource.photo)));
        expect(find.byType(EvidenceCameraPage), findsOneWidget);
        expect(tester.widget<FilledButton>(shutter).onPressed, isNotNull);
        await completeCapture(tester);
        h.expectStep(5);
        h.expectNext(false);
        final evidence = tester
            .widget<EvidenceStep>(find.byType(EvidenceStep))
            .evidence!;
        expect(evidence.items.length, i + 1);
        expect(cameras[i].disposes, 1);
      }
      final state = tester
          .widget<EvidenceStep>(find.byType(EvidenceStep))
          .evidence!;
      // Exercise the existing Edit callbacks and guide reentry: both drafts survive.
      originalArea.onEditLocation();
      await tester.pumpAndSettle();
      h.expectStep(3);
      await h.next();
      h.expectStep(4);
      expect(h.input, 'corner');
      final restored = tester.widget<AffectedAreaStep>(h.step);
      expect(restored.issueSummary, originalArea.issueSummary);
      expect(restored.locationSummary, originalArea.locationSummary);
      expect(restored.selectedArea, 'Other');
      await h.next();
      await h.tap(find.text('Start Adding Evidence'));
      h.expectStep(5);
      expect(
        tester.widget<EvidenceStep>(find.byType(EvidenceStep)).evidence,
        same(state),
      );
      expect(state.items.length, 2);
      final first = state.items.first;
      await h.tap(find.byKey(ValueKey(first.id)));
      expect(state.selected, same(first));
      final problems = <String>[];
      collectLayoutProblems(tester, h.page, 'photos', problems);
      expect(problems, isEmpty, reason: problems.join());
      final deletes = find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip?.startsWith('Delete photo') == true,
      );
      await h.tap(deletes.first);
      expect(state.items.length, 1);
      await h.tap(deletes.first);
      expect(state.items, isEmpty);
      expect(state.selected, isNull);
      expect(find.byKey(const ValueKey('evidence-add')), findsOneWidget);
      h.expectNext(false);
      // Cancellation adds nothing.
      await h.tap(find.byKey(const ValueKey('evidence-add')));
      await h.tap(find.byKey(const ValueKey(EvidenceSource.photo)));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(state.items, isEmpty);
      // Previous textual draft is still owned by the original creation flow.
      final pageStep = tester.widget<EvidenceStep>(find.byType(EvidenceStep));
      expect(pageStep.evidence, same(state));
      h.expectStep(5);
    },
  );
  testWidgets(
    'Evidence controller preserves original file, selection, and deletion',
    (tester) async {
      final photo = await tester.runAsync(
        () => EvidenceModel.fromCapture(photoFile()),
      );
      final second = await tester.runAsync(
        () => EvidenceModel.fromCapture(photoFile()),
      );
      final state = EvidenceController();
      state.add(photo!);
      state.add(second!);
      expect(photo.id, isNot(second.id));
      expect(state.items.length, 2);
      expect(state.selected, same(second));
      state.select(photo.id);
      expect(state.selected, same(photo));
      expect(() => state.items.clear(), throwsUnsupportedError);
      state.add(photo);
      expect(state.items.length, 2);
      state.remove(second.id);
      expect(state.selected, same(photo));
      state.remove(photo.id);
      expect(state.selected, isNull);
      state.dispose();
    },
  );
  testWidgets('Empty and corrupt files cannot become evidence', (tester) async {
    for (final bytes in [
      Uint8List(0),
      Uint8List.fromList([1, 2, 3]),
      Uint8List.fromList([255, 216, 255]),
    ]) {
      await tester.runAsync(() async {
        await expectLater(
          EvidenceModel.fromCapture(XFile.fromData(bytes, name: 'bad.jpg')),
          throwsA(anything),
        );
      });
    }
  });
  testWidgets(
    'Lifecycle changes during initialization dispose stale session and resume safely',
    (tester) async {
      final first = FakeCamera()..initGate = Completer<void>();
      final second = FakeCamera();
      var calls = 0;
      await openCamera(tester, () => calls++ == 0 ? first : second);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      first.initGate!.complete();
      await tester.pumpAndSettle();
      expect(first.disposes, 1);
      expect(second.initializes, 1);
      expect(tester.widget<FilledButton>(shutter).onPressed, isNotNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(second.disposes, 1);
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
        'Camera responsive SIZE SCALE'
            .replaceAll('SIZE', size.toString())
            .replaceAll('SCALE', scale.toString()),
        (tester) async {
          await openCamera(tester, FakeCamera.new, size: size, scale: scale);
          final problems = <String>[];
          collectLayoutProblems(
            tester,
            find.byType(EvidenceCameraPage),
            'camera',
            problems,
          );
          expect(problems, isEmpty, reason: problems.join());
          expect(shutter.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
      testWidgets(
        'Photo previews scroll without overflow SIZE SCALE'
            .replaceAll('SIZE', size.toString())
            .replaceAll('SCALE', scale.toString()),
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final evidence = EvidenceController();
          addTearDown(evidence.dispose);
          final photo = await tester.runAsync(
            () => EvidenceModel.fromCapture(photoFile()),
          );
          final second = await tester.runAsync(
            () => EvidenceModel.fromCapture(photoFile()),
          );
          evidence.add(photo!);
          evidence.add(second!);
          await tester.pumpWidget(
            MaterialApp(
              theme: buildTheme(Brightness.light),
              home: Scaffold(
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
                    child: Column(
                      children: [
                        Expanded(
                          child: EvidenceStep(evidence: evidence, onAdd: () {}),
                        ),
                        const SizedBox(height: 16),
                        const CaseCreationBottom(
                          enabled: false,
                          onNext: null,
                          label: 'Check',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final problems = <String>[];
          collectLayoutProblems(
            tester,
            find.byType(Scaffold),
            'photo preview',
            problems,
          );
          expect(problems, isEmpty, reason: problems.join());
          await tester.ensureVisible(
            find.byKey(const ValueKey('evidence-add')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('evidence-add')).hitTestable(),
            findsOneWidget,
          );
          expect(find.text('Check').hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final entry in <String, String>{
    'CameraAccessDenied': 'Camera access was denied. Allow camera access in your device or browser settings. On web, use HTTPS or localhost.',
    'cameraNotFound': 'No camera was found on this device.',
    'cameraNotReadable': 'The camera could not be opened. Close other camera apps or tabs, then try again.',
    'cameraOverconstrained': 'The camera could not start with the requested settings. Please try again.',
    'cameraType': 'Camera access is unavailable in this browser context. Use HTTPS or localhost and check browser settings.',
    'cameraSecurity': 'Camera access is unavailable in this browser context. Use HTTPS or localhost and check browser settings.',
    'cameraNotSupported': 'This browser does not support camera access.',
    'cameraMissingMetadata':
        'Unable to use the camera. Check camera access and try again.',
    'UnexpectedInitializationFailure':
        'Unable to use the camera. Check camera access and try again.',
  }.entries) {
    testWidgets(
      'Web error category ${entry.key} has specific message and preserves retry',
      (tester) async {
        final bad = FakeCamera()
          ..initError = CameraException(
            entry.key,
            'original browser description',
          );
        final good = FakeCamera();
        var calls = 0;
        await openCamera(tester, () => calls++ == 0 ? bad : good);
        expect(find.text(entry.value), findsOneWidget);
        expect(tester.widget<FilledButton>(shutter).onPressed, isNull);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(shutter).onPressed, isNotNull);
        expect(good.initializes, 1);
        expect(bad.disposes, 1);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(good.disposes, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
