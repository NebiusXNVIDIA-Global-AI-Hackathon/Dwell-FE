import 'package:dwell/features/cases/widgets/creation/evidence/evidence_audio_amplitude_wave.dart';

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dwell/core/theme.dart';
import 'package:dwell/features/cases/models/evidence_model.dart';
import 'package:dwell/features/cases/pages/evidence/evidence_audio_page.dart';
import 'package:dwell/features/cases/services/evidence_audio_recorder.dart';
import 'package:dwell/features/cases/widgets/creation/evidence/evidence_audio_preview.dart';
import 'package:dwell/features/cases/widgets/creation/evidence/evidence_add_sheet.dart';
import 'package:dwell/features/cases/widgets/creation/steps/evidence_step.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:record/record.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'helpers/case_creation_test_harness.dart';
import 'helpers/fake_evidence_video_player.dart';

late Directory storage;
late XFile raw;
final toggle = find.byKey(const ValueKey('audio-record-toggle'));

class FakeRecorder implements EvidenceAudioRecorder {
  final stream = StreamController<RecordState>.broadcast();
  final amplitudeStream = StreamController<Amplitude>.broadcast();
  @override
  Stream<Amplitude> get amplitudes => amplitudeStream.stream;
  bool permission = true;
  Object? startError, stopError;
  Completer<void>? startGate;
  Completer<XFile>? stopGate;
  int starts = 0, stops = 0, disposals = 0;
  bool disposed = false;
  @override
  Stream<RecordState> get states => stream.stream;
  @override
  Future<bool> hasPermission() async => permission;
  @override
  Future<void> start() async {
    starts++;
    await startGate?.future;
    if (startError != null) throw startError!;
  }

  @override
  Future<XFile> stop() async {
    stops++;
    if (stopError != null) throw stopError!;
    return stopGate == null ? raw : await stopGate!.future;
  }

  @override
  Future<void> dispose() async {
    if (disposed) return;
    disposed = true;
    disposals++;
    await stream.close();
    await amplitudeStream.close();
  }
}

Future<EvidenceModel> model({Duration duration = const Duration(seconds: 2)}) =>
    EvidenceModel.fromAudio(raw, duration: duration, storageDirectory: storage);
Future<void> open(
  WidgetTester tester,
  FakeRecorder recorder, {
  EvidenceAudioSaver? saver,
  void Function(EvidenceModel?)? result,
  Duration Function()? elapsed,
  Size size = const Size(393, 844),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final value = await Navigator.of(context).push<EvidenceModel>(
                MaterialPageRoute(
                  builder: (_) => EvidenceAudioPage(
                    recorderFactory: () => recorder,
                    saveAudio: saver,
                    elapsed: elapsed,
                  ),
                ),
              );
              result?.call(value);
            },
            child: const Text('Open audio'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open audio'));
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  for (var i = 0; i < 6; i++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  await tester.pumpAndSettle();
}

void main() {
  late FakeEvidenceVideoPlayer player;
  late VideoPlayerPlatform previous;
  setUpAll(loadCreationTestFonts);
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('audio-test-');
    raw = XFile(
      (await File('${storage.path}/source.m4a').writeAsBytes([
        0,
        0,
        0,
        24,
        102,
        116,
        121,
        112,
        77,
        52,
        65,
        32,
        0,
        0,
        0,
        0,
      ])).path,
    );
    previous = VideoPlayerPlatform.instance;
    player = FakeEvidenceVideoPlayer()
      ..duration = const Duration(seconds: 2)
      ..size = Size.zero;
    VideoPlayerPlatform.instance = player;
  });
  tearDown(() async {
    VideoPlayerPlatform.instance = previous;
    if (await storage.exists()) await storage.delete(recursive: true);
  });
  test('Owned audio copy validates headers, duration and file size; cleanup waits for readers', () async {
    final audio = await model();
    expect(audio.type, EvidenceType.audio);
    expect(audio.mimeType, 'audio/mp4');
    expect(audio.file.path, isNot(raw.path));
    audio.retainVideo();
    var deleted = false;
    final pending = audio.dispose().then((_) => deleted = true);
    await Future<void>.delayed(Duration.zero);
    expect(deleted, isFalse);
    audio.releaseVideo();
    await pending;
    expect(await File(audio.file.path).exists(), isFalse);
    expect(await File(raw.path).exists(), isTrue);
    await expectLater(model(duration: Duration.zero), throwsFormatException);

    await expectLater(
      EvidenceModel.fromAudio(
        XFile.fromData(Uint8List.fromList([1, 2, 3])),
        duration: const Duration(seconds: 1),
        storageDirectory: storage,
      ),
      throwsFormatException,
    );
  });
  testWidgets('Start/stop under five seconds, preview, upload exactly once', (
    tester,
  ) async {
    final audio = await tester.runAsync(model);
    final recorder = FakeRecorder();
    EvidenceModel? result;
    var saves = 0;
    await open(
      tester,
      recorder,
      saver: (_) async {
        saves++;
        return audio!;
      },
      result: (v) => result = v,
    );
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const ValueKey('audio-upload')))
          .onPressed,
      isNull,
    );
    await tap(tester, toggle);
    await tester.pump(const Duration(seconds: 1));
    await tap(tester, toggle);
    expect(saves, 1);
    expect(recorder.stops, 1);
    expect(recorder.disposals, 1);
    expect(find.byType(EvidenceAudioPreview), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('evidence-audio-play')));
    expect(player.plays, 1);
    await tap(tester, find.byKey(const ValueKey('evidence-audio-play')));
    expect(player.pauses, greaterThanOrEqualTo(1));
    await tap(tester, find.byKey(const ValueKey('audio-upload')));
    expect(result, same(audio));
    await tester.runAsync(() => audio!.dispose());
  });
  testWidgets(
    'Permission rejection and native errors recover without adding evidence',
    (tester) async {
      final recorder = FakeRecorder()..permission = false;
      await open(tester, recorder);
      await tap(tester, toggle);
      expect(
        find.textContaining('Microphone access was denied'),
        findsOneWidget,
      );
      expect(recorder.starts, 0);
      expect(recorder.disposals, 1);
      await tap(tester, find.byTooltip('Back'));
      expect(find.byType(EvidenceAudioPage), findsNothing);
      final failed = FakeRecorder()
        ..startError = PlatformException(code: 'mic_busy');
      await open(tester, failed);
      await tap(tester, toggle);
      expect(
        find.textContaining('Unable to record or play audio'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(failed.disposals, 1);
      await tap(tester, find.byTooltip('Back'));
    },
  );
  testWidgets(
    'Back and background cancel active recording; no stop/save result',
    (tester) async {
      var saves = 0;
      EvidenceModel? result;
      final recorder = FakeRecorder();
      await open(
        tester,
        recorder,
        saver: (_) async {
          saves++;
          return (await model());
        },
        result: (v) => result = v,
      );
      await tap(tester, toggle);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(saves, 0);
      expect(recorder.disposals, 1);
      final background = FakeRecorder();
      await open(tester, background);
      await tap(tester, toggle);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(background.disposals, 1);
      expect(
        find.textContaining('cancelled when the app became inactive'),
        findsOneWidget,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      await tap(tester, find.byTooltip('Back'));
    },
  );
  testWidgets(
    'Pending start ignores double taps; timeout clears loading and late result is cancelled',
    (tester) async {
      final recorder = FakeRecorder()..startGate = Completer<void>();
      await open(tester, recorder);
      await tester.tap(toggle);
      await tester.pump();
      await tester.tap(toggle);
      await tester.pump();
      expect(recorder.starts, 1);
      await tester.pump(const Duration(seconds: 16));
      await tester.pumpAndSettle();
      expect(find.textContaining('timed out'), findsOneWidget);
      expect(tester.widget<IconButton>(toggle).onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      recorder.startGate!.complete();
      await tester.pumpAndSettle();
      await tap(tester, find.byTooltip('Back'));
      expect(recorder.disposals, 1);
    },
  );
  testWidgets(
    'Stop failure, invalid file and player initialization errors never complete upload',
    (tester) async {
      final recorder = FakeRecorder()
        ..stopError = PlatformException(code: 'stop_failed');
      EvidenceModel? result;
      await open(tester, recorder, result: (v) => result = v);
      await tap(tester, toggle);
      await tap(tester, toggle);
      expect(result, isNull);
      expect(find.byType(EvidenceAudioPreview), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tap(tester, find.byTooltip('Back'));
      player.initializationError = PlatformException(
        code: 'bad_audio',
        message: 'Cannot decode audio',
      );
      await tester.runAsync(() async {
        await expectLater(
          saveEvidenceAudio(raw),
          throwsA(isA<PlatformException>()),
        );
      });
      player.initializationError = null;
      player.duration = Duration.zero;
      await tester.runAsync(() async {
        await expectLater(saveEvidenceAudio(raw), throwsFormatException);
      });
    },
  );
  testWidgets('Retake discards the private file and leaves Upload disabled', (
    tester,
  ) async {
    final audio = await tester.runAsync(model);
    final recorder = FakeRecorder();
    await open(tester, recorder, saver: (_) async => audio!);
    await tap(tester, toggle);
    await tap(tester, toggle);
    await tester.tap(find.byKey(const ValueKey('audio-retake')));
    await tester.pump();
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(
      await tester.runAsync(() => File(audio!.file.path).exists()),
      isFalse,
    );
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const ValueKey('audio-upload')))
          .onPressed,
      isNull,
    );
    await tap(tester, find.byTooltip('Back'));
  });
  testWidgets(
    'Audio menu returns to Step 5 preserving photo/video; selection, pause and delete',
    (tester) async {
      final audio = await tester.runAsync(model);
      final video = await tester.runAsync(
        () => EvidenceModel.fromVideo(
          raw,
          duration: const Duration(seconds: 6),
          storageDirectory: storage,
        ),
      );
      final bytes = (await rootBundle.load(
        'assets/images/evidence_guide/overall_view.png',
      )).buffer.asUint8List();
      final photo = await tester.runAsync(
        () => EvidenceModel.fromFile(XFile.fromData(bytes, name: 'photo.png')),
      );
      var calls = 0;
      final gate = Completer<EvidenceModel?>();
      final h = await CreationHarness.start(
        tester,
        direct: true,
        recordAudio: (_) {
          calls++;
          return gate.future;
        },
      );
      await h.toArea();
      await h.choose('Ceiling');
      await h.next();
      await h.tap(find.text('Start Adding Evidence'));
      final controller = tester
          .widget<EvidenceStep>(find.byType(EvidenceStep))
          .evidence!;
      controller.add(photo!);
      controller.add(video!);
      await tester.pumpAndSettle();
      await h.tap(find.byKey(const ValueKey('evidence-add')));
      await h.tap(find.byKey(const ValueKey(EvidenceSource.audio)));
      final add = tester.widget<EvidenceStep>(find.byType(EvidenceStep)).onAdd;
      add();
      add();
      await tester.pump();
      expect(calls, 1);
      gate.complete(audio);
      await tester.pumpAndSettle();
      expect(controller.items, [photo, video, audio]);
      expect(find.byType(EvidenceAudioPreview), findsOneWidget);
      await h.tap(find.byKey(const ValueKey('evidence-audio-play')));
      final pauses = player.pauses;
      await tap(tester, find.byKey(ValueKey(photo.id)));
      expect(find.byType(EvidenceAudioPreview), findsNothing);
      expect(player.disposals, greaterThan(0));
      await h.tap(find.byKey(ValueKey(audio!.id)));
      expect(find.text('00:00 / 00:02'), findsOneWidget);
      await h.tap(find.byTooltip('Delete audio 3'));
      expect(controller.items, [photo, video]);
      h.expectNext(false);
      expect(player.pauses, greaterThanOrEqualTo(pauses));
      await tester.pumpWidget(const SizedBox());
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      await tester.runAsync(() async {
        await audio.dispose();
        await video.dispose();
      });
    },
  );
  testWidgets(
    'Three-minute design cap stops automatically; recording Upload finishes safely',
    (tester) async {
      final audio = await tester.runAsync(model);
      final recorder = FakeRecorder();
      Duration elapsed = Duration.zero;
      await open(
        tester,
        recorder,
        elapsed: () => elapsed,
        saver: (_) async => audio!,
      );
      await tap(tester, toggle);
      elapsed = const Duration(minutes: 3);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(recorder.stops, 1);
      expect(find.byType(EvidenceAudioPreview), findsOneWidget);
      await tap(tester, find.byTooltip('Back'));
      await tester.runAsync(() => audio!.dispose());
      final next = FakeRecorder();
      final other = await tester.runAsync(model);
      EvidenceModel? result;
      await open(
        tester,
        next,
        saver: (_) async => other!,
        result: (v) => result = v,
      );
      await tap(tester, toggle);
      await tap(tester, find.byKey(const ValueKey('audio-upload')));
      expect(next.stops, 1);
      expect(result, same(other));
      await tester.runAsync(() => other!.dispose());
    },
  );
  testWidgets(
    'Decoder success copies valid audio; missing, empty and stalled decoder fail with bounded cleanup',
    (tester) async {
      await tester.runAsync(() async {
        final saved = await saveEvidenceAudio(raw, storageDirectory: storage);
        expect(saved.duration, const Duration(seconds: 2));
        expect(await File(saved.file.path).length(), await raw.length());
        await saved.dispose();
        await expectLater(
          saveEvidenceAudio(XFile('${storage.path}/missing.m4a')),
          throwsA(isA<FileSystemException>()),
        );
        final empty = await File('${storage.path}/empty.m4a').writeAsBytes([]);
        await expectLater(
          saveEvidenceAudio(XFile(empty.path)),
          throwsFormatException,
        );
        player.createGate = Completer<void>();
        final watch = Stopwatch()..start();
        await expectLater(
          saveEvidenceAudio(
            raw,
            validationTimeout: const Duration(milliseconds: 20),
            cleanupTimeout: const Duration(milliseconds: 20),
          ),
          throwsA(isA<TimeoutException>()),
        );
        expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
        player.createGate!.complete();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
    },
  );
  testWidgets(
    'Stop/save duplicate taps and recording interruption discard without upload',
    (tester) async {
      final audio = await tester.runAsync(model);
      final recorder = FakeRecorder()..stopGate = Completer<XFile>();
      var saves = 0;
      await open(
        tester,
        recorder,
        saver: (_) async {
          saves++;
          return audio!;
        },
      );
      await tap(tester, toggle);
      await tester.tap(toggle);
      await tester.pump();
      await tester.tap(toggle);
      await tester.pump();
      expect(recorder.stops, 1);
      recorder.stopGate!.complete(raw);
      await tester.pumpAndSettle();
      expect(saves, 1);
      await tap(tester, find.byTooltip('Back'));
      final interrupted = FakeRecorder();
      await open(tester, interrupted);
      await tap(tester, toggle);
      interrupted.stream.add(RecordState.pause);
      await tester.pumpAndSettle();
      expect(find.textContaining('Recording was interrupted'), findsOneWidget);
      expect(interrupted.disposals, 1);
      expect(find.byType(EvidenceAudioPreview), findsNothing);
      await tap(tester, find.byTooltip('Back'));
    },
  );
  testWidgets(
    'Record Audio sheet opens the full-screen page and Upload appends its result',
    (tester) async {
      final audio = await tester.runAsync(model);
      final recorder = FakeRecorder();
      final h = await CreationHarness.start(
        tester,
        direct: true,
        recordAudio: (context) => Navigator.of(context).push<EvidenceModel>(
          MaterialPageRoute(
            builder: (_) => EvidenceAudioPage(
              recorderFactory: () => recorder,
              saveAudio: (_) async => audio!,
            ),
          ),
        ),
      );
      await h.toArea();
      await h.choose('Ceiling');
      await h.next();
      await h.tap(find.text('Start Adding Evidence'));
      await h.tap(find.byKey(const ValueKey('evidence-add')));
      await h.tap(find.byKey(const ValueKey(EvidenceSource.audio)));
      expect(find.byType(EvidenceAudioPage), findsOneWidget);
      expect(find.text('Record Audio'), findsOneWidget);
      await tap(tester, toggle);
      await tap(tester, toggle);
      await tap(tester, find.byKey(const ValueKey('audio-upload')));
      expect(find.byType(EvidenceAudioPage), findsNothing);
      expect(
        tester.widget<EvidenceStep>(find.byType(EvidenceStep)).evidence!.items,
        [audio],
      );
      h.expectNext(false);
      await tester.pumpWidget(const SizedBox());
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      await tester.runAsync(() => audio!.dispose());
    },
  );
  testWidgets(
    'Back during a pending stop drops its late file and never saves evidence',
    (tester) async {
      final recorder = FakeRecorder()..stopGate = Completer<XFile>();
      var saves = 0;
      EvidenceModel? result;
      await open(
        tester,
        recorder,
        saver: (_) async {
          saves++;
          return (await model());
        },
        result: (v) => result = v,
      );
      await tap(tester, toggle);
      await tester.tap(toggle);
      await tester.pump();
      await tester.tap(find.byTooltip('Back'));
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.byType(EvidenceAudioPage), findsNothing);
      expect(result, isNull);
      recorder.stopGate!.complete(raw);
      await tester.pumpAndSettle();
      expect(saves, 0);
      expect(recorder.disposals, 1);
    },
  );
  testWidgets(
    'Stop timeout clears loading and blocks another native recording until reopening',
    (tester) async {
      final recorder = FakeRecorder()..stopGate = Completer<XFile>();
      await open(tester, recorder);
      await tap(tester, toggle);
      await tester.tap(toggle);
      await tester.pump(const Duration(seconds: 16));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('timed out'), findsOneWidget);
      expect(tester.widget<IconButton>(toggle).onPressed, isNull);
      recorder.stopGate!.complete(raw);
      await tester.pumpAndSettle();
      await tap(tester, find.byTooltip('Back'));
      expect(recorder.stops, 1);
    },
  );
  testWidgets(
    'Meter history grows from input, freezes after stop, clears on retake and cancel',
    (tester) async {
      final audio = await tester.runAsync(model);
      final recorder = FakeRecorder();
      await open(tester, recorder, saver: (_) async => audio!);
      List<double> levels() => tester
          .widget<EvidenceAudioAmplitudeWave>(
            find.byType(EvidenceAudioAmplitudeWave),
          )
          .levels;
      expect(levels(), isEmpty);
      await tap(tester, toggle);
      expect(recorder.amplitudeStream.hasListener, isTrue);
      for (final db in [-60.0, -48.0, 0.0]) {
        recorder.amplitudeStream.add(Amplitude(current: db, max: db));
        await tester.pump(const Duration(milliseconds: 120));
      }
      expect(levels().length, 3);
      final captured = List<double>.of(levels());
      await tap(tester, toggle);
      expect(recorder.amplitudeStream.hasListener, isFalse);
      expect(levels(), captured);
      expect(audio!.audioLevels, captured);
      await tester.pump(const Duration(seconds: 2));
      expect(levels(), captured);
      await tap(tester, find.byKey(const ValueKey('audio-retake')));
      expect(levels(), isEmpty);
      expect(audio.audioLevels, isEmpty);
      await tap(tester, find.byTooltip('Back'));
      final cancelled = FakeRecorder();
      await open(tester, cancelled);
      await tap(tester, toggle);
      cancelled.amplitudeStream.add(Amplitude(current: -10, max: -10));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(levels(), isEmpty);
      expect(cancelled.amplitudeStream.hasListener, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      await tap(tester, find.byTooltip('Back'));
    },
  );
  for (final size in [const Size(320, 568), const Size(393, 844)]) {
    testWidgets('Audio layout does not overflow at $size', (tester) async {
      await open(tester, FakeRecorder(), size: size);
      expect(tester.takeException(), isNull);
      await tap(tester, toggle);
      expect(tester.takeException(), isNull);
      await tap(tester, find.byTooltip('Back'));
    });
  }
}
