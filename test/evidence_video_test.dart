import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dwell/core/theme.dart';
import 'package:dwell/features/cases/models/evidence_model.dart';
import 'package:dwell/features/cases/pages/evidence/evidence_video_page.dart';
import 'package:dwell/features/cases/services/evidence_video_camera.dart';
import 'package:dwell/features/cases/widgets/creation/evidence/evidence_camera_cover_preview.dart';
import 'package:dwell/features/cases/widgets/creation/evidence/evidence_add_sheet.dart';
import 'package:dwell/features/cases/widgets/creation/steps/evidence_step.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'case_creation_layout_test.dart' show collectLayoutProblems;
import 'helpers/case_creation_test_harness.dart';
import 'helpers/fake_evidence_video_player.dart';

late Directory storage;
late XFile rawVideo;
late Uint8List photoBytes;
final record = find.byKey(const ValueKey('video-record'));

class FakeVideoCamera extends ChangeNotifier implements EvidenceVideoCamera {
  Completer<void>? initGate;
  Completer<void>? startGate;
  Completer<XFile>? stopGate;
  Object? initError;
  Object? startError;
  Object? stopError;
  @override
  String? errorDescription;
  int initializes = 0;
  int starts = 0;
  int stops = 0;
  int discards = 0;
  int disposals = 0;
  bool recording = false;
  @override
  Future<void> initialize() async {
    initializes++;
    await initGate?.future;
    if (initError != null) throw initError!;
  }

  @override
  Widget buildPreview({Widget? overlay}) => EvidenceCameraCoverPreview(
    aspectRatio: 3 / 4,
    preview: const ColoredBox(color: Colors.grey),
    overlay: overlay,
  );
  @override
  Future<void> startRecording() async {
    starts++;
    await startGate?.future;
    if (startError != null) throw startError!;
    recording = true;
  }

  @override
  Future<XFile> stopRecording() async {
    stops++;
    if (stopError != null) throw stopError!;
    final file = stopGate != null ? await stopGate!.future : rawVideo;
    recording = false;
    return file;
  }

  @override
  Future<void> discardFile(XFile file) async {
    discards++;
  }

  @override
  Future<void> dispose() async {
    try {
      if (recording) {
        await stopRecording();
        await discardFile(rawVideo);
      }
    } finally {
      disposals++;
      super.dispose();
    }
  }
}

Future<EvidenceModel> saveFakeVideo(XFile file, Duration elapsed) =>
    EvidenceModel.fromVideo(file, duration: elapsed, storageDirectory: storage);

Future<void> openVideo(
  WidgetTester tester,
  EvidenceVideoCamera Function() camera, {
  EvidenceVideoSaver? saver,
  void Function(EvidenceModel?)? onResult,
  Size size = const Size(393, 844),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final prepared = saver == null
      ? await tester.runAsync(
          () => saveFakeVideo(rawVideo, const Duration(seconds: 5)),
        )
      : null;
  DateTime? origin;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            final result = await Navigator.of(context).push<EvidenceModel>(
              MaterialPageRoute(
                builder: (_) => EvidenceVideoPage(
                  cameraFactory: camera,
                  saveVideo: saver ?? (_, _) async => prepared!,
                  elapsed: () => tester.binding.clock.now().difference(
                    origin ?? tester.binding.clock.now(),
                  ),
                ),
              ),
            );
            onResult?.call(result);
          },
          child: const Text('Open video'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open video'));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
  if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
    await tester.pumpAndSettle();
  }
  // The injected clock starts on the test's first recording interaction.
  origin = tester.binding.clock.now();
}

Future<void> stopAndSave(WidgetTester tester) async {
  await tester.tap(record);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await loadCreationTestFonts();
    photoBytes = (await rootBundle.load(
      'assets/images/evidence_guide/overall_view.png',
    )).buffer.asUint8List();
  });
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('dwell-video-test-');
    final file = await File('${storage.path}/source.mp4').writeAsBytes([
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
    ]);
    rawVideo = XFile(file.path);
  });
  tearDown(() async {
    if (await storage.exists()) await storage.delete(recursive: true);
  });

  testWidgets(
    'Minimum five seconds disables Stop; success saves once and releases camera',
    (tester) async {
      final camera = FakeVideoCamera()..stopGate = Completer<XFile>();
      EvidenceModel? result;
      await openVideo(
        tester,
        () => camera,
        onResult: (value) => result = value,
      );
      expect(
        ModalRoute.of(tester.element(find.byType(EvidenceVideoPage))),
        isA<MaterialPageRoute<EvidenceModel>>(),
      );
      expect(find.byKey(const ValueKey('video-instruction')), findsOneWidget);
      await tester.tap(record);
      await tester.pump();
      expect(find.byKey(const ValueKey('video-instruction')), findsNothing);
      expect(camera.starts, 1);
      expect(tester.widget<FilledButton>(record).onPressed, isNull);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('00:04'), findsOneWidget);
      await tester.tap(record);
      expect(camera.stops, 0);
      expect(result, isNull);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:05'), findsOneWidget);
      final stop = tester.widget<FilledButton>(record).onPressed!;
      stop();
      stop();
      await tester.pump();
      expect(camera.stops, 1);
      camera.stopGate!.complete(rawVideo);
      await tester.pumpAndSettle();
      expect(result?.type, EvidenceType.video);
      expect(result?.duration, const Duration(seconds: 5));
      expect(camera.discards, 1);
      expect(camera.disposals, 1);
      expect(find.byType(EvidenceVideoPage), findsNothing);
      await tester.runAsync(() => result!.dispose());
      expect(tester.takeException(), isNull);
    },
  );

  for (final error in [
    CameraException('CameraAccessDenied', ''),
    CameraException('AudioAccessDenied', ''),
    CameraException('NoCamera', ''),
  ]) {
    testWidgets('Initialization error ${error.code} allows retry and exit', (
      tester,
    ) async {
      final bad = FakeVideoCamera()..initError = error;
      final good = FakeVideoCamera();
      var calls = 0;
      await openVideo(tester, () => calls++ == 0 ? bad : good);
      expect(find.text(evidenceVideoError(error)), findsOneWidget);
      expect(bad.disposals, 1);
      expect(tester.widget<FilledButton>(record).onPressed, isNull);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(good.initializes, 1);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(good.disposals, 1);
      expect(tester.takeException(), isNull);
    });
  }

  for (final recording in [false, true]) {
    testWidgets('Back cancels without evidence while recording=$recording', (
      tester,
    ) async {
      final camera = FakeVideoCamera();
      EvidenceModel? result;
      await openVideo(
        tester,
        () => camera,
        onResult: (value) => result = value,
      );
      if (recording) {
        await tester.tap(record);
        await tester.pump(const Duration(seconds: 2));
      }
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(camera.disposals, 1);
      expect(camera.stops, recording ? 1 : 0);
      expect(camera.discards, recording ? 1 : 0);
      await tester.pump(const Duration(seconds: 10));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Start duplicates, pending Back and late completion clean up without returning evidence',
    (tester) async {
      final camera = FakeVideoCamera()..startGate = Completer<void>();
      EvidenceModel? result;
      await openVideo(
        tester,
        () => camera,
        onResult: (value) => result = value,
      );
      final start = tester.widget<FilledButton>(record).onPressed!;
      start();
      start();
      await tester.pump();
      expect(camera.starts, 1);
      await tester.binding.handlePopRoute();
      await tester.pump();
      camera.startGate!.complete();
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(camera.stops, 1);
      expect(camera.disposals, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Background cancels recording; resume creates a fresh camera', (
    tester,
  ) async {
    final first = FakeVideoCamera();
    final second = FakeVideoCamera();
    var calls = 0;
    await openVideo(tester, () => calls++ == 0 ? first : second);
    await tester.tap(record);
    await tester.pump(const Duration(seconds: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(first.disposals, 1);
    expect(first.discards, 1);
    expect(second.initializes, 1);
    expect(find.text('00:00'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(second.disposals, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pending initialization released after cancel and resume', (
    tester,
  ) async {
    final first = FakeVideoCamera()..initGate = Completer<void>();
    final second = FakeVideoCamera();
    var calls = 0;
    await openVideo(tester, () => calls++ == 0 ? first : second);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    first.initGate!.complete();
    await tester.pumpAndSettle();
    expect(first.disposals, 1);
    expect(second.initializes, 1);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(second.disposals, 1);
  });

  testWidgets('Back during native stop discards late video and never saves', (
    tester,
  ) async {
    final camera = FakeVideoCamera()..stopGate = Completer<XFile>();
    var saves = 0;
    EvidenceModel? result;
    await openVideo(
      tester,
      () => camera,
      onResult: (value) => result = value,
      saver: (_, _) async {
        saves++;
        throw StateError('must not save');
      },
    );
    await tester.tap(record);
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(record);
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    camera.stopGate!.complete(rawVideo);
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(saves, 0);
    expect(camera.discards, 1);
    expect(camera.disposals, 1);
    expect(find.byType(EvidenceVideoPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final stage in ['start', 'stop', 'save', 'recording']) {
    testWidgets('$stage failure adds nothing and releases camera', (
      tester,
    ) async {
      final camera = FakeVideoCamera();
      final error = StateError('native failure');
      if (stage == 'start') camera.startError = error;
      if (stage == 'stop') camera.stopError = error;
      EvidenceModel? result;
      await openVideo(
        tester,
        () => camera,
        onResult: (value) => result = value,
        saver: stage == 'save' ? (_, _) async => throw error : null,
      );
      await tester.tap(record);
      await tester.pump();
      if (stage == 'recording') {
        camera.errorDescription = 'device error';
        camera.notifyListeners();
        await tester.pumpAndSettle();
      } else if (stage != 'start') {
        await tester.pump(const Duration(seconds: 5));
        await stopAndSave(tester);
      } else {
        await tester.pumpAndSettle();
      }
      expect(result, isNull);
      expect(find.text('Retry'), findsOneWidget);
      await tester.pump();
      expect(camera.disposals, 1);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Video ownership, minimum duration and playback leases protect files',
    (tester) async {
      await tester.runAsync(() async {
        await expectLater(
          EvidenceModel.fromVideo(
            rawVideo,
            duration: const Duration(seconds: 4),
            storageDirectory: storage,
          ),
          throwsFormatException,
        );
        final video = await saveFakeVideo(rawVideo, const Duration(seconds: 5));
        expect(video.file.path, isNot(rawVideo.path));
        expect(video.mimeType, 'video/mp4');
        expect(video.bytes, isEmpty);
        video.retainVideo();
        final deletion = video.dispose();
        expect(await File(video.file.path).exists(), isTrue);
        video.releaseVideo();
        await deletion;
        expect(await File(video.file.path).exists(), isFalse);
        expect(await File(rawVideo.path).exists(), isTrue);
      });
    },
  );

  testWidgets('Encoded duration is independently validated before saving', (
    tester,
  ) async {
    final platform = FakeEvidenceVideoPlayer()
      ..duration = const Duration(seconds: 4);
    final original = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = platform;
    addTearDown(() => VideoPlayerPlatform.instance = original);
    await tester.runAsync(() async {
      await expectLater(
        saveEvidenceVideo(rawVideo, const Duration(seconds: 6)),
        throwsFormatException,
      );
    });
    expect(platform.disposals, 1);
  });

  testWidgets(
    'Record Video menu reaches page, mixed evidence selects, plays, pauses and deletes',
    (tester) async {
      final platform = FakeEvidenceVideoPlayer();
      final original = VideoPlayerPlatform.instance;
      VideoPlayerPlatform.instance = platform;
      addTearDown(() => VideoPlayerPlatform.instance = original);
      final camera = FakeVideoCamera();
      final prepared = await tester.runAsync(
        () => saveFakeVideo(rawVideo, const Duration(seconds: 5)),
      );
      DateTime? origin;
      final h = await CreationHarness.start(
        tester,
        direct: true,
        recordVideo: (context) => Navigator.of(context).push<EvidenceModel>(
          MaterialPageRoute(
            builder: (_) => EvidenceVideoPage(
              cameraFactory: () => camera,
              saveVideo: (_, _) async => prepared!,
              elapsed: () => tester.binding.clock.now().difference(
                origin ?? tester.binding.clock.now(),
              ),
            ),
          ),
        ),
      );
      await h.toArea();
      await h.choose('Ceiling');
      await h.next();
      await h.tap(find.text('Start Adding Evidence'));
      final state = tester
          .widget<EvidenceStep>(find.byType(EvidenceStep))
          .evidence!;
      final photo = await tester.runAsync(
        () => EvidenceModel.fromFile(
          XFile.fromData(photoBytes, name: 'photo.png'),
        ),
      );
      state.add(photo!);
      await tester.pumpAndSettle();
      final add = tester.widget<EvidenceStep>(find.byType(EvidenceStep)).onAdd;
      add();
      add();
      await tester.pumpAndSettle();
      expect(find.byType(EvidenceAddSheet), findsOneWidget);
      await h.tap(find.byKey(const ValueKey(EvidenceSource.video)));
      add();
      await tester.pump();
      expect(find.byType(EvidenceAddSheet), findsNothing);
      expect(find.byType(EvidenceVideoPage), findsOneWidget);
      origin = tester.binding.clock.now();
      await tester.tap(record);
      await tester.pump(const Duration(seconds: 5));
      await stopAndSave(tester);

      h.expectStep(5);
      expect(state.items.length, 2);
      final video = state.items.last;
      expect(video.type, EvidenceType.video);
      expect(state.items.first, same(photo));
      expect(state.selected, same(video));

      await tester.tap(find.byTooltip('Play video'));
      await tester.pump();
      expect(platform.plays, 1);
      await tester.tap(find.byTooltip('Pause video'));
      await tester.pump();
      expect(platform.pauses, greaterThanOrEqualTo(1));
      await tester.tap(find.byTooltip('Play video'));
      await tester.pump();
      final paused = platform.pauses;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(platform.pauses, greaterThan(paused));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      await h.tap(find.byKey(ValueKey(photo.id)));
      expect(state.selected, same(photo));

      await h.tap(find.byKey(ValueKey(video.id)));
      expect(state.selected, same(video));

      await h.tap(find.byTooltip('Delete video 2'));
      for (var attempt = 0; attempt < 10; attempt++) {
        await tester.pump();
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        });
      }
      await tester.pump();
      expect(state.items, [photo]);
      expect(state.selected, same(photo));
      expect(
        await tester.runAsync(() => File(video.file.path).exists()),
        isFalse,
      );

      expect(platform.disposals, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Native stop timeout clears loading and late file is discarded', (
    tester,
  ) async {
    final camera = FakeVideoCamera()..stopGate = Completer<XFile>();
    var saves = 0;
    await openVideo(
      tester,
      () => camera,
      saver: (_, _) async {
        saves++;
        throw StateError('must not save');
      },
    );
    await tester.tap(record);
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(record);
    await tester.pump(const Duration(seconds: 21));
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(saves, 0);
    camera.stopGate!.complete(rawVideo);
    await tester.pumpAndSettle();
    expect(camera.discards, greaterThanOrEqualTo(1));
    expect(camera.disposals, 1);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Missing native plugin reports channel error despite unresolved creation',
    (tester) async {
      final platform = FakeEvidenceVideoPlayer()
        ..platformInitializationError = PlatformException(
          code: 'channel-error',
          message: 'Unable to establish connection',
        );
      final original = VideoPlayerPlatform.instance;
      VideoPlayerPlatform.instance = platform;
      addTearDown(() => VideoPlayerPlatform.instance = original);
      await tester.runAsync(() async {
        final gate = Completer<void>();
        platform.createGate = gate;
        await expectLater(
          saveEvidenceVideo(
            rawVideo,
            const Duration(seconds: 11),
            validationTimeout: const Duration(milliseconds: 100),
            cleanupTimeout: const Duration(milliseconds: 20),
          ),
          throwsA(isA<PlatformException>()),
        );
        gate.complete();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      expect(platform.disposals, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Decoder initialization timeout never becomes saved evidence', (
    tester,
  ) async {
    final platform = FakeEvidenceVideoPlayer()..sendInitialized = false;
    final original = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = platform;
    addTearDown(() => VideoPlayerPlatform.instance = original);
    await tester.runAsync(() async {
      await expectLater(
        saveEvidenceVideo(
          rawVideo,
          const Duration(seconds: 11),
          validationTimeout: const Duration(milliseconds: 20),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });
    expect(platform.disposals, 1);
  });

  testWidgets('Empty recording fails before a decoder is created', (
    tester,
  ) async {
    final platform = FakeEvidenceVideoPlayer();
    final original = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = platform;
    addTearDown(() => VideoPlayerPlatform.instance = original);
    await tester.runAsync(() async {
      final empty = await File('${storage.path}/empty.mp4').writeAsBytes([]);
      await expectLater(
        saveEvidenceVideo(XFile(empty.path), const Duration(seconds: 11)),
        throwsFormatException,
      );
    });
    expect(platform.creates, 0);
  });

  for (final viewport in [
    const Size(320, 568),
    const Size(393, 600),
    const Size(844, 220),
  ]) {
    testWidgets(
      'Cover preview fills viewport without distorting at $viewport',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1000, 1000);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        for (final ratio in [3 / 4, 9 / 16, 16 / 9]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Center(
                child: SizedBox(
                  width: viewport.width,
                  height: viewport.height,
                  child: EvidenceCameraCoverPreview(
                    aspectRatio: ratio,
                    preview: const ColoredBox(
                      key: ValueKey('cover-source'),
                      color: Colors.grey,
                    ),
                    overlay: const SizedBox.expand(
                      key: ValueKey('cover-overlay'),
                    ),
                  ),
                ),
              ),
            ),
          );
          final source = tester.getSize(
            find.byKey(const ValueKey('cover-source')),
          );
          final overlay = tester.getSize(
            find.byKey(const ValueKey('cover-overlay')),
          );
          expect(source.width / source.height, closeTo(ratio, 0.00001));
          expect(overlay, viewport);
          final transform = tester
              .renderObject(find.byKey(const ValueKey('cover-source')))
              .getTransformTo(null);
          expect(transform.storage[0], closeTo(transform.storage[5], 0.00001));
          expect(
            source.width * transform.storage[0],
            greaterThanOrEqualTo(viewport.width - 0.01),
          );
          expect(
            source.height * transform.storage[5],
            greaterThanOrEqualTo(viewport.height - 0.01),
          );
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  for (final size in [const Size(320, 568), const Size(393, 844)]) {
    testWidgets('Video layout safe and readable at $size', (tester) async {
      final camera = FakeVideoCamera();
      await openVideo(tester, () => camera, size: size);
      final problems = <String>[];
      collectLayoutProblems(
        tester,
        find.byType(EvidenceVideoPage),
        'video',
        problems,
      );
      expect(problems, isEmpty);
      expect(record.hitTestable(), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    });
  }
}
