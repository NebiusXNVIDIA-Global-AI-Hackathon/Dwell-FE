import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dwell/features/cases/models/evidence_model.dart';
import 'package:dwell/features/cases/services/evidence_audio_recorder.dart';
import 'package:dwell/features/cases/services/evidence_media_source.dart';
import 'package:dwell/features/cases/services/evidence_media_validation.dart';
import 'package:dwell/features/cases/services/evidence_video_camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:video_player/video_player.dart';

import 'helpers/fake_evidence_video_player.dart';

class FakeSources {
  final live = <String>{};
  int releases = 0;
  XFile add(String id) {
    live.add(id);
    return _FakeSource(id);
  }

  Future<void> remove(XFile file) async {
    releases++;
    live.remove(file.path);
  }
}

class _FakeSource extends XFile {
  _FakeSource(super.path);
  @override
  Future<int> length() async => 16;
}

class FakeNativeRecorder extends AudioRecorder {
  FakeNativeRecorder(this.file);
  final XFile file;
  Completer<void>? disposeGate;
  bool fail = false;
  int cancellations = 0;
  @override
  Future<bool> isEncoderSupported(AudioEncoder encoder) async => true;
  @override
  Future<void> start(RecordConfig config, {required String path}) async {}
  @override
  Future<String?> stop() async => file.path;
  @override
  Future<void> cancel() async {
    cancellations++;
  }

  @override
  Future<void> dispose() async {
    await disposeGate?.future;
    if (fail) throw StateError('Native release failed');
  }
}

void main() {
  late Directory storage;
  late XFile raw;
  late FakeEvidenceVideoPlayer platform;
  late VideoPlayerPlatform previous;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('validation-test-');
    final file = await File('${storage.path}/raw.mp4').writeAsBytes([
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
    raw = XFile(file.path);
    previous = VideoPlayerPlatform.instance;
    platform = FakeEvidenceVideoPlayer();
    VideoPlayerPlatform.instance = platform;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.llfbandit.record/messages'),
          (_) async => null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => storage.path,
        );
  });
  tearDown(() async {
    VideoPlayerPlatform.instance = previous;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.llfbandit.record/messages'),
          null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await storage.delete(
      recursive: true,
    ); // fixtures; never a real native reader
  });

  test('Multiple readers and repeated cleanup requests release a source exactly once', () async {
    final sources = FakeSources();
    final file = sources.add('blob:shared-readers');
    final first = EvidenceMediaSources.retain(file);
    final second = EvidenceMediaSources.retain(file);
    final cleanup = EvidenceMediaSources.dispose(
      file,
      () => sources.remove(file),
    );
    final duplicate = EvidenceMediaSources.dispose(
      file,
      () => sources.remove(file),
    );
    expect(identical(cleanup, duplicate), true);
    first.release();
    first.release();
    expect(sources.releases, 0);
    second.release();
    await cleanup;
    expect(sources.releases, 1);
    expect(sources.live, isEmpty);
  });

  for (final audio in [false, true]) {
    final label = audio ? 'Audio' : 'Video';
    testWidgets('$label publishes only after confirmed native release', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final model = audio
            ? await saveEvidenceAudio(raw, storageDirectory: storage)
            : await saveEvidenceVideo(raw, const Duration(seconds: 6));
        expect(platform.completedDisposals, 1);
        expect(model.file.path, isNot(raw.path));
        await DeviceEvidenceVideoCamera().discardFile(raw);
        expect(await File(model.file.path).exists(), true);
        await model.dispose();
      });
    });

    Future<EvidenceModel> validate(
      FakeSources sources,
      XFile probe, {
      int timeout = 20,
      Future<EvidenceModel> Function(XFile, Duration)? store,
    }) => validateEvidenceMedia(
      raw,
      audio: audio,
      validationTimeout: Duration(milliseconds: timeout),
      cleanupTimeout: const Duration(milliseconds: 20),
      prepare: (_) async => probe,
      playerFactory: (file) => VideoPlayerController.networkUrl(
        Uri.parse(file.path),
        videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true),
      ),
      releasePrepared: sources.remove,
      store: store ?? (_, _) async => throw StateError('Must not publish'),
    );

    testWidgets(
      '$label dispose timeout retains actual file and fake Blob until late native release',
      (tester) async {
        await tester.runAsync(() async {
          final sources = FakeSources();
          final probe = sources.add('blob:$label-delay');
          platform.disposeGate = Completer<void>();
          // Native source case: the player references the actual capture file.
          final validating = validateEvidenceMedia(
            raw,
            audio: audio,
            cleanupTimeout: const Duration(milliseconds: 20),
            store: (_, _) async => throw StateError('Must not publish'),
          );
          await expectLater(validating, throwsA(isA<TimeoutException>()));
          final blobValidation = validate(sources, probe);
          await expectLater(blobValidation, throwsA(isA<TimeoutException>()));
          var deleted = false;
          final cleanup = DeviceEvidenceVideoCamera()
              .discardFile(raw)
              .then((_) => deleted = true);
          expect(await File(raw.path).exists(), true);
          expect(deleted, false);
          expect(sources.live, contains(probe.path));
          expect(sources.releases, 0);
          platform.disposeGate!.complete();
          await cleanup;
          for (var i = 0; i < 100 && sources.releases == 0; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 2));
          }
          expect(sources.live, isEmpty);
          expect(platform.completedDisposals, 2);
        });
      },
    );

    testWidgets(
      '$label rejected creation releases its source despite SDK dispose orphan',
      (tester) async {
        await tester.runAsync(() async {
          final sources = FakeSources();
          final probe = sources.add('blob:$label-rejected');
          platform.creationError = PlatformException(code: 'create_failed');
          await expectLater(
            validate(sources, probe),
            throwsA(isA<PlatformException>()),
          );
          await Future<void>.delayed(const Duration(milliseconds: 10));
          expect(sources.live, isEmpty);
          expect(platform.disposals, 0);
        });
      },
    );

    testWidgets(
      '$label pending creation preserves source and disposes late allocation',
      (tester) async {
        await tester.runAsync(() async {
          final sources = FakeSources();
          final probe = sources.add('blob:$label-create-late');
          platform.createGate = Completer<void>();
          await expectLater(
            validate(sources, probe),
            throwsA(isA<TimeoutException>()),
          );
          expect(sources.live, contains(probe.path));
          expect(platform.disposals, 0);
          platform.createGate!.complete();
          for (var i = 0; i < 100 && sources.releases == 0; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 2));
          }
          expect(sources.live, isEmpty);
          expect(platform.completedDisposals, 1);
        });
      },
    );

    testWidgets(
      '$label permanently pending creation never invents source release',
      (tester) async {
        await tester.runAsync(() async {
          final sources = FakeSources();
          final probe = sources.add('blob:$label-create-never');
          platform.createGate = Completer<void>();
          await expectLater(
            validate(sources, probe),
            throwsA(isA<TimeoutException>()),
          );
          expect(sources.releases, 0);
          expect(
            EvidenceMediaSources.status(probe),
            EvidenceSourceStatus.cleanupPending,
          );
          expect(platform.disposals, 0);
        });
      },
    );

    testWidgets(
      '$label failed native disposal is distinct from timeout and preserves source',
      (tester) async {
        await tester.runAsync(() async {
          final sources = FakeSources();
          final probe = sources.add('blob:$label-dispose-failed');
          platform.disposalError = StateError('Native failure');
          await expectLater(
            validate(sources, probe),
            throwsA(isA<EvidenceMediaReleaseException>()),
          );
          expect(sources.releases, 0);
          expect(platform.completedDisposals, 0);
          expect(
            EvidenceMediaSources.status(probe),
            EvidenceSourceStatus.nativeReleaseFailed,
          );
        });
      },
    );

    testWidgets(
      '$label initialization failure cleans up only after native disposal',
      (tester) async {
        await tester.runAsync(() async {
          final sources = FakeSources();
          final probe = sources.add('blob:$label-init-failed');
          platform.initializationError = PlatformException(
            code: 'metadata_failed',
            message: 'Metadata failed',
          );
          platform.disposeGate = Completer<void>();
          await expectLater(
            validate(sources, probe),
            throwsA(isA<PlatformException>()),
          );
          expect(sources.releases, 0);
          platform.disposeGate!.complete();
          for (var i = 0; i < 100 && sources.releases == 0; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 2));
          }
          expect(sources.live, isEmpty);
        });
      },
    );

    testWidgets('$label too-short metadata never reaches storage', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final sources = FakeSources();
        final probe = sources.add('blob:$label-invalid');
        platform.duration = Duration.zero;
        await expectLater(validate(sources, probe), throwsFormatException);
        for (var i = 0; i < 100 && sources.releases == 0; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }
        expect(sources.live, isEmpty);
        expect(platform.completedDisposals, 1);
      });
    });
  }

  testWidgets(
    'Synchronous controller construction failure returns the acquired source lease',
    (tester) async {
      await tester.runAsync(() async {
        final sources = FakeSources();
        final probe = sources.add('blob:constructor-failure');
        await expectLater(
          validateEvidenceMedia(
            raw,
            audio: true,
            prepare: (_) async => probe,
            releasePrepared: sources.remove,
            playerFactory: (_) => throw StateError('Factory rejected'),
            store: (_, _) async => throw StateError('Must not publish'),
          ),
          throwsStateError,
        );
        await Future<void>.delayed(Duration.zero);
        expect(sources.live, isEmpty);
      });
    },
  );

  testWidgets(
    'Recorder native release does not delete a capture still used by validation',
    (tester) async {
      await tester.runAsync(() async {
        final capture = await Directory('${storage.path}/capture').create();
        final file = XFile(
          (await File('${capture.path}/capture.m4a').writeAsBytes([
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
        final native = FakeNativeRecorder(file);
        final recorder = DeviceEvidenceAudioRecorder(
          recorder: native,
          createDirectory: () async => capture,
        );
        await recorder.start();
        await recorder.stop();
        platform.disposeGate = Completer<void>();
        await expectLater(
          validateEvidenceMedia(
            file,
            audio: true,
            cleanupTimeout: const Duration(milliseconds: 20),
            store: (_, _) async => throw StateError('Must not publish'),
          ),
          throwsA(isA<TimeoutException>()),
        );
        final closing = recorder.dispose();
        await expectLater(
          closing.timeout(const Duration(milliseconds: 20)),
          throwsA(isA<TimeoutException>()),
        );
        expect(await File(file.path).exists(), true);
        expect(await capture.exists(), true);
        platform.disposeGate!.complete();
        await closing;
        expect(await capture.exists(), false);
        expect(native.cancellations, 0);
      });
    },
  );

  testWidgets(
    'Late copy retains its source until real completion and discards unpublished model',
    (tester) async {
      await tester.runAsync(() async {
        final gate = Completer<void>();
        final copy = evidenceSourceOperation(
          raw,
          () async {
            await gate.future;
            return EvidenceModel.fromAudio(
              raw,
              duration: const Duration(seconds: 6),
              storageDirectory: storage,
            );
          },
          timeout: const Duration(milliseconds: 20),
          onLateResult: (model) => model.dispose(),
        );
        await expectLater(copy, throwsA(isA<TimeoutException>()));
        final cleanup = DeviceEvidenceVideoCamera().discardFile(raw);
        expect(await File(raw.path).exists(), true);
        gate.complete();
        await cleanup;
        expect(await File(raw.path).exists(), false);
        expect(await storage.list().length, 0);
      });
    },
  );

  for (final failed in [false, true]) {
    testWidgets(
      'Recorder ${failed ? 'failed' : 'delayed'} disposal preserves capture directory',
      (tester) async {
        await tester.runAsync(() async {
          final capture = await Directory('${storage.path}/capture').create();
          final file = XFile(
            (await File('${capture.path}/capture.m4a').writeAsBytes([1, 2, 3]))
                .path,
          );
          final native = FakeNativeRecorder(file)
            ..fail = failed
            ..disposeGate = Completer<void>();
          final recorder = DeviceEvidenceAudioRecorder(
            recorder: native,
            createDirectory: () async => capture,
          );
          await recorder.start();
          await recorder.stop();
          final closing = recorder.dispose();
          if (failed) {
            native.disposeGate!.complete();
            await expectLater(closing, throwsStateError);
            expect(await capture.exists(), true);
          } else {
            await expectLater(
              closing.timeout(const Duration(milliseconds: 20)),
              throwsA(isA<TimeoutException>()),
            );
            expect(await capture.exists(), true);
            native.disposeGate!.complete();
            await closing;
            expect(await capture.exists(), false);
          }
        });
      },
    );
  }
}
