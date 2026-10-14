import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dwell/features/cases/services/evidence_camera.dart';
import 'package:dwell/features/cases/services/evidence_camera_lease.dart';
import 'package:dwell/features/cases/services/evidence_media_source.dart';
import 'package:dwell/features/cases/services/evidence_video_camera.dart';
import 'package:dwell/features/cases/services/evidence_video_diagnostics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'evidence_camera_test.dart' show openCamera, shutter;
import 'evidence_video_test.dart' show openVideo, record;
import 'helpers/case_creation_test_harness.dart' show loadCreationTestFonts;

const description = CameraDescription(
  name: 'fake-back',
  lensDirection: CameraLensDirection.back,
  sensorOrientation: 90,
);

class FakeNativeCamera extends CameraController {
  FakeNativeCamera(this.file) : super(description, ResolutionPreset.high);
  final XFile file;
  Completer<void>? initializeGate, startGate, disposeGate;
  Completer<XFile>? captureGate, stopGate;
  Object? disposeError, initializeError, startError, stopError;
  int initializes = 0, captures = 0, starts = 0, stops = 0, disposals = 0;
  @override
  Future<void> initialize() async {
    initializes++;
    await initializeGate?.future;
    if (initializeError != null) throw initializeError!;
    value = value.copyWith(
      isInitialized: true,
      previewSize: const Size(640, 480),
    );
  }

  @override
  Widget buildPreview() => const ColoredBox(color: Colors.grey);
  @override
  Future<XFile> takePicture() async {
    captures++;
    return captureGate == null ? file : await captureGate!.future;
  }

  @override
  Future<void> startVideoRecording({
    void Function(CameraImage)? onAvailable,
    bool enablePersistentRecording = true,
  }) async {
    starts++;
    await startGate?.future;
    if (startError != null) throw startError!;
    value = value.copyWith(
      isRecordingVideo: true,
      recordingOrientation: const Optional.of(DeviceOrientation.portraitUp),
    );
  }

  @override
  Future<XFile> stopVideoRecording() async {
    stops++;
    if (stopError != null) throw stopError!;
    final result = stopGate == null ? file : await stopGate!.future;
    value = value.copyWith(isRecordingVideo: false);
    return result;
  }

  @override
  Future<void> dispose() async {
    disposals++;
    await disposeGate?.future;
    if (disposeError != null) throw disposeError!;
    await super.dispose();
  }
}

void main() {
  late Directory storage;
  late XFile file;
  late EvidenceCameraLeaseManager manager;
  late List<FakeNativeCamera> controllers;
  setUpAll(loadCreationTestFonts);
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('shared-camera-test-');
    file = XFile(
      (await File('${storage.path}/capture.mp4').writeAsBytes([
        0,
        0,
        0,
        24,
        102,
        116,
        121,
        112,
        105,
        115,
        111,
        109,
        0,
        0,
        0,
        0,
      ])).path,
    );
    manager = EvidenceCameraLeaseManager();
    controllers = [];
  });
  tearDown(() async {
    await storage.delete(recursive: true);
  });
  DeviceEvidenceCamera photo(FakeNativeCamera controller) =>
      DeviceEvidenceCamera(
        leaseManager: manager,
        enumerate: () async => [description],
        controllerFactory: (_, _, _) {
          controllers.add(controller);
          return controller;
        },
      );
  DeviceEvidenceVideoCamera video(FakeNativeCamera controller) =>
      DeviceEvidenceVideoCamera(
        leaseManager: manager,
        enumerate: () async => [description],
        controllerFactory: (_, _, _) {
          controllers.add(controller);
          return controller;
        },
      );
  final busy = throwsA(
    isA<CameraException>().having((e) => e.code, 'code', 'CameraBusy'),
  );

  testWidgets('Production photo and video adapters share the exact singleton', (
    tester,
  ) async {
    final p = DeviceEvidenceCamera(
      enumerate: () async => [],
      controllerFactory: (_, _, _) => throw StateError('No controller'),
    );
    final v = DeviceEvidenceVideoCamera(
      enumerate: () async => [],
      controllerFactory: (_, _, _) => throw StateError('No controller'),
    );
    expect(identical(p.leaseManager, v.leaseManager), true);
    await expectLater(p.initialize(), throwsA(isA<CameraException>()));
    await expectLater(v.initialize(), busy);
    await v.dispose(); // A failed acquirer cannot return somebody else's lease.
    expect(p.leaseManager.status, EvidenceCameraLeaseStatus.active);
    await p.dispose();
    expect(p.leaseManager.status, isNull);
  });

  for (final photoFirst in [true, false]) {
    testWidgets(
      '${photoFirst ? 'Photo' : 'Video'} failed initialization completes cleanup across error zones',
      (tester) async {
        final native = FakeNativeCamera(file)
          ..initializeError = StateError('Native initialization failed');
        final dynamic active = photoFirst ? photo(native) : video(native);
        await expectLater(
          recordVideoStage(
            'test initialization',
            () => active.initialize() as Future<void>,
          ),
          throwsStateError,
        );
        await recordVideoStage(
          'test release',
          () => active.dispose() as Future<void>,
        );
        expect(native.disposals, 1);
        expect(manager.status, isNull);
      },
    );
    testWidgets(
      '${photoFirst ? 'Photo → Video' : 'Video → Photo'} sequential switching releases native hardware first',
      (tester) async {
        final p = photo(FakeNativeCamera(file));
        final v = video(FakeNativeCamera(file));
        if (photoFirst) {
          await p.initialize();
          await p.takePicture();
          await expectLater(v.initialize(), busy);
          await v.dispose();
          await p.dispose();
          final next = video(FakeNativeCamera(file));
          await next.initialize();
          await next.dispose();
        } else {
          await v.initialize();
          await v.startRecording();
          await v.stopRecording();
          await expectLater(p.initialize(), busy);
          await p.dispose();
          await v.dispose();
          final next = photo(FakeNativeCamera(file));
          await next.initialize();
          await next.dispose();
        }
        expect(controllers.length, 2);
        expect(manager.status, isNull);
      },
    );

    testWidgets(
      '${photoFirst ? 'Photo' : 'Video'} unfinished initialization blocks both adapters after timeout',
      (tester) async {
        final native = FakeNativeCamera(file)
          ..initializeGate = Completer<void>();
        final dynamic active = photoFirst ? photo(native) : video(native);
        final Future<void> initializing = active.initialize();
        await tester.pump();
        expect(native.initializes, 1);
        final closing = expectLater(
          active.dispose() as Future<void>,
          throwsA(isA<TimeoutException>()),
        );
        await tester.pump(
          evidenceCameraReleaseTimeout + const Duration(seconds: 1),
        );
        await closing;
        expect(manager.status, EvidenceCameraLeaseStatus.pendingRelease);
        await expectLater(photo(FakeNativeCamera(file)).initialize(), busy);
        await expectLater(video(FakeNativeCamera(file)).initialize(), busy);
        expect(controllers.length, 1);
        expect(native.disposals, 0);
        native.initializeGate!.complete();
        await initializing;
        await active.released;
        expect(native.disposals, 1);
        expect(manager.status, isNull);
      },
    );

    testWidgets(
      '${photoFirst ? 'Photo' : 'Video'} permanently unfinished initialization never returns hardware ownership',
      (tester) async {
        final native = FakeNativeCamera(file)
          ..initializeGate = Completer<void>();
        final dynamic active = photoFirst ? photo(native) : video(native);
        unawaited(active.initialize() as Future<void>);
        await tester.pump();
        expect(native.initializes, 1);
        final closing = expectLater(
          active.dispose() as Future<void>,
          throwsA(isA<TimeoutException>()),
        );
        await tester.pump(
          evidenceCameraReleaseTimeout + const Duration(seconds: 1),
        );
        await closing;
        await expectLater(photo(FakeNativeCamera(file)).initialize(), busy);
        await expectLater(video(FakeNativeCamera(file)).initialize(), busy);
        expect(native.disposals, 0);
        expect(controllers.length, 1);
      },
    );

    testWidgets(
      '${photoFirst ? 'Photo' : 'Video'} delayed native disposal permits reentry only after real completion',
      (tester) async {
        final native = FakeNativeCamera(file)..disposeGate = Completer<void>();
        final dynamic active = photoFirst ? photo(native) : video(native);
        await active.initialize();
        final Future<void> original = active.dispose();
        expect(identical(original, active.dispose()), true);
        final closing = expectLater(original, throwsA(isA<TimeoutException>()));
        await tester.pump(
          evidenceCameraReleaseTimeout + const Duration(seconds: 1),
        );
        await closing;
        await expectLater(photo(FakeNativeCamera(file)).initialize(), busy);
        await expectLater(video(FakeNativeCamera(file)).initialize(), busy);
        native.disposeGate!.complete();
        await active.released;
        expect(native.disposals, 1);
        await expectLater(
          active.initialize() as Future<void>,
          throwsA(
            isA<CameraException>().having(
              (e) => e.code,
              'code',
              'CameraClosed',
            ),
          ),
        );
        final next = photo(FakeNativeCamera(file));
        await next.initialize();
        // A repeated old dispose must not return the new session's ownership.
        await expectLater(
          active.dispose() as Future<void>,
          throwsA(isA<TimeoutException>()),
        );
        expect(manager.status, EvidenceCameraLeaseStatus.active);
        await next.dispose();
      },
    );

    testWidgets(
      '${photoFirst ? 'Photo' : 'Video'} native disposal failure quarantines its shared lease',
      (tester) async {
        final native = FakeNativeCamera(file)
          ..disposeError = StateError('Native failure');
        final dynamic active = photoFirst ? photo(native) : video(native);
        await active.initialize();
        await expectLater(active.dispose() as Future<void>, throwsStateError);
        expect(manager.status, EvidenceCameraLeaseStatus.releaseFailed);
        await expectLater(photo(FakeNativeCamera(file)).initialize(), busy);
        await expectLater(video(FakeNativeCamera(file)).initialize(), busy);
        expect(native.disposals, 1);
        expect(controllers.length, 1);
      },
    );
  }

  for (final stop in [false, true]) {
    testWidgets(
      'Rejected recording ${stop ? 'stop' : 'start'} does not become a permanently pending error-zone barrier',
      (tester) async {
        final native = FakeNativeCamera(file);
        final v = video(native);
        await v.initialize();
        if (stop) {
          await v.startRecording();
          native.stopError = StateError('Native stop failed');
          await expectLater(
            recordVideoStage('test stop', v.stopRecording),
            throwsStateError,
          );
        } else {
          native.startError = StateError('Native start failed');
          await expectLater(
            recordVideoStage('test start', v.startRecording),
            throwsStateError,
          );
        }
        await recordVideoStage('test release', v.dispose);
        expect(native.disposals, 1);
        expect(manager.status, isNull);
      },
    );
    testWidgets(
      'Pending recording ${stop ? 'stop' : 'start'} retains ownership through late completion',
      (tester) async {
        final native = FakeNativeCamera(file);
        final v = video(native);
        await v.initialize();
        Future<void> operation;
        if (stop) {
          await v.startRecording();
          native.stopGate = Completer<XFile>();
          operation = v.stopRecording().then((_) {});
        } else {
          native.startGate = Completer<void>();
          operation = v.startRecording();
        }
        final closing = expectLater(
          v.dispose(),
          throwsA(isA<TimeoutException>()),
        );
        await tester.pump(
          evidenceCameraReleaseTimeout + const Duration(seconds: 1),
        );
        await closing;
        await expectLater(photo(FakeNativeCamera(file)).initialize(), busy);
        expect(native.disposals, 0);
        if (stop) {
          native.stopGate!.complete(file);
        } else {
          native.startGate!.complete();
        }
        await operation;
        await v.released;
        expect(native.stops, 1);
        expect(native.disposals, 1);
        expect(manager.status, isNull);
      },
    );
  }

  testWidgets('Permanently pending recording never returns the shared lease', (
    tester,
  ) async {
    final native = FakeNativeCamera(file)..startGate = Completer<void>();
    final v = video(native);
    await v.initialize();
    unawaited(v.startRecording());
    final closing = expectLater(v.dispose(), throwsA(isA<TimeoutException>()));
    await tester.pump(
      evidenceCameraReleaseTimeout + const Duration(seconds: 1),
    );
    await closing;
    await expectLater(photo(FakeNativeCamera(file)).initialize(), busy);
    expect(native.disposals, 0);
  });

  testWidgets(
    'Rapid video Retry cannot allocate while a photo release is pending',
    (tester) async {
      final native = FakeNativeCamera(file)..disposeGate = Completer<void>();
      final p = photo(native);
      await p.initialize();
      final closing = expectLater(
        p.dispose(),
        throwsA(isA<TimeoutException>()),
      );
      await tester.pump(const Duration(seconds: 6));
      await closing;
      DeviceEvidenceVideoCamera? latest;
      await openVideo(
        tester,
        () => latest = video(FakeNativeCamera(file)),
        saver: (_, _) async => throw StateError('Must not save'),
      );
      expect(find.textContaining('Previous camera cleanup'), findsOneWidget);
      for (var i = 0; i < 8; i++) {
        await tester.tap(find.text('Retry'));
        await tester.pump();
      }
      expect(controllers.length, 1);
      native.disposeGate!.complete();
      await p.released;
      await tester.pump();
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(controllers.length, 2);
      expect(manager.status, EvidenceCameraLeaseStatus.active);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await latest!.released;
      expect(manager.status, isNull);
    },
  );

  testWidgets(
    'Captured file readers do not hold a released camera hardware lease',
    (tester) async {
      final native = FakeNativeCamera(file);
      final v = video(native);
      await v.initialize();
      await v.startRecording();
      final source = EvidenceMediaSources.retain(file);
      await v.dispose();
      expect(manager.status, isNull);
      expect(await tester.runAsync(() => File(file.path).exists()), true);
      expect(
        EvidenceMediaSources.status(file),
        EvidenceSourceStatus.cleanupPending,
      );
      final p = photo(FakeNativeCamera(file));
      await p.initialize();
      source.release();
      var cleaned = false;
      unawaited(v.discardFile(file).then((_) => cleaned = true));
      for (var i = 0; i < 100 && !cleaned; i++) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 2)),
        );
      }
      expect(cleaned, true);
      await p.dispose();
    },
  );

  testWidgets(
    'Photo route closes during capture; late result cannot affect the next video session',
    (tester) async {
      final native = FakeNativeCamera(file)..captureGate = Completer<XFile>();
      final p = photo(native);
      var discarded = 0;
      await openCamera(
        tester,
        () => p,
        discardPhoto: (_) async {
          discarded++;
        },
      );
      await tester.tap(shutter);
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await expectLater(video(FakeNativeCamera(file)).initialize(), busy);
      expect(native.disposals, 0);
      native.captureGate!.complete(file);
      await tester.pump();
      await p.released;
      final v = video(FakeNativeCamera(file));
      await v.initialize();
      await tester.pump();
      expect(discarded, 1);
      expect(manager.status, EvidenceCameraLeaseStatus.active);
      await v.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Video Back stays bounded while native initialization is pending',
    (tester) async {
      final native = FakeNativeCamera(file)..initializeGate = Completer<void>();
      final v = video(native);
      await openVideo(
        tester,
        () => v,
        saver: (_, _) async => throw StateError('Must not save'),
      );
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.text('Open video'), findsOneWidget);
      await expectLater(photo(FakeNativeCamera(file)).initialize(), busy);
      native.initializeGate!.complete();
      await tester.pump();
      await v.released;
      expect(manager.status, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Video background cleanup holds ownership through pending cancellation stop',
    (tester) async {
      final native = FakeNativeCamera(file)..stopGate = Completer<XFile>();
      final v = video(native);
      DeviceEvidenceVideoCamera? resumed;
      var launches = 0;
      await openVideo(
        tester,
        () => launches++ == 0 ? v : resumed = video(FakeNativeCamera(file)),
        saver: (_, _) async => throw StateError('Must not save'),
      );
      await tester.tap(record);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump(const Duration(seconds: 6));
      await expectLater(photo(FakeNativeCamera(file)).initialize(), busy);
      expect(native.disposals, 0);
      native.stopGate!.complete(file);
      await tester.pump();
      await v.released;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(controllers.length, 2);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await resumed!.released;
      expect(tester.takeException(), isNull);
    },
  );
}
