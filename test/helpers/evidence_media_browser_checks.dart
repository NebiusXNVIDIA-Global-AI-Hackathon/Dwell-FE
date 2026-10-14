import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;
import 'package:dwell/features/cases/services/evidence_media_platform.dart';
import 'package:dwell/features/cases/services/evidence_audio_recorder.dart';
import 'package:dwell/features/cases/services/evidence_video_camera.dart';
import 'package:dwell/features/cases/services/evidence_video_thumbnail.dart';
import 'package:dwell/features/cases/controllers/evidence_controller.dart';
import 'package:camera/camera.dart';
import 'package:video_player_web/video_player_web.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:dwell/features/cases/models/evidence_model.dart';
import 'package:dwell/features/cases/services/evidence_library.dart';
import 'package:dwell/features/cases/services/evidence_player_session.dart';
import 'package:dwell/features/cases/services/evidence_media_validation.dart';
import 'package:dwell/features/cases/services/evidence_media_source.dart';

import 'fake_evidence_video_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  VideoPlayerPlatform.instance = VideoPlayerPlugin();
  test('Validation disposal timeout keeps actual Blob URLs valid until native release', () async {
    final previous = VideoPlayerPlatform.instance;
    final fake = FakeEvidenceVideoPlayer()..disposeGate = Completer<void>();
    VideoPlayerPlatform.instance = fake;
    final data = Uint8List.fromList([
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
    final raw = createEvidenceBlob(data, 'video/mp4', 'raw.mp4');
    final prepared = createEvidenceBlob(data, 'video/mp4', 'prepared.mp4');
    try {
      await expectLater(
        validateEvidenceMedia(
          raw,
          audio: false,
          prepare: (_) async => prepared,
          cleanupTimeout: const Duration(milliseconds: 20),
          store: (_, _) async => throw StateError('Must not publish'),
        ),
        throwsA(isA<TimeoutException>()),
      );
      expect(await XFile(prepared.path).readAsBytes(), data);
      expect(
        EvidenceMediaSources.status(prepared),
        EvidenceSourceStatus.cleanupPending,
      );
      fake.disposeGate!.complete();
      for (
        var i = 0;
        i < 100 && EvidenceMediaSources.status(prepared) != null;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }
      await expectLater(XFile(prepared.path).readAsBytes(), throwsA(anything));
    } finally {
      if (!fake.disposeGate!.isCompleted) fake.disposeGate!.complete();
      releaseEvidenceBlob(raw);
      VideoPlayerPlatform.instance = previous;
    }
  });
  test('Photo ownership: borrowed URLs survive, owned selections revoke exactly once', () async {
    final data = (await rootBundle.load(
      'assets/images/evidence_guide/overall_view.png',
    )).buffer.asUint8List();
    final borrowed = createEvidenceBlob(data, 'image/png', 'original.png');
    try {
      final model = await EvidenceModel.fromFile(borrowed);
      expect(model.bytes, data);
      await model.dispose();
      expect(model.bytes, isEmpty);
      expect(model.cleanupStatus, EvidenceCleanupStatus.completed);
      expect(await XFile(borrowed.path).readAsBytes(), data);
    } finally {
      releaseEvidenceBlob(borrowed);
    }
    final captureFile = createEvidenceBlob(data, 'image/png', 'capture.png');
    final capture = await EvidenceModel.fromCapture(captureFile);
    expect(capture.bytes, data);
    expect(await XFile(captureFile.path).readAsBytes(), data);
    await Future.wait([capture.dispose(), capture.dispose()]);
    expect(capture.bytes, isEmpty);
    await expectLater(XFile(captureFile.path).readAsBytes(), throwsA(anything));
    final delayedFile = createEvidenceBlob(data, 'image/png', 'delayed.png');
    final cleanupGate = Completer<void>();
    var cleanups = 0;
    final delayed = await EvidenceModel.fromFile(
      delayedFile,
      cleanup: () async {
        cleanups++;
        await cleanupGate.future;
        await releaseOwnedPhoto(delayedFile);
      },
    );
    await expectLater(delayed.dispose(), throwsA(isA<TimeoutException>()));
    expect(delayed.cleanupStatus, EvidenceCleanupStatus.pending);
    expect(delayed.bytes, isEmpty);
    // A bounded UI wait must not revoke a still-owned source.
    expect(await XFile(delayedFile.path).readAsBytes(), data);
    cleanupGate.complete();
    await delayed.cleanupCompletion;
    expect(delayed.cleanupStatus, EvidenceCleanupStatus.completed);
    expect(cleanups, 1);
    await expectLater(XFile(delayedFile.path).readAsBytes(), throwsA(anything));
    for (var i = 0; i < 3; i++) {
      final good = createEvidenceBlob(data, 'image/png', 'selected.png');
      final bad = createEvidenceBlob(
        Uint8List.fromList([1]),
        'image/png',
        'bad.png',
      );
      final releases = <String>[];
      final picker = DeviceEvidenceLibrary(
        pickImages: () async => [good, bad],
        releasePhoto: (file) async {
          releases.add(file.path);
          await releaseOwnedPhoto(file);
        },
      );
      final result = await picker.pickPhotos();
      expect(result.photos.length, 1);
      expect(result.failedCount, 1);
      expect(await XFile(good.path).readAsBytes(), data);
      await expectLater(XFile(bad.path).readAsBytes(), throwsA(anything));
      final controller = EvidenceController()..add(result.photos.single);
      expect(result.photos.single.bytes, data);
      controller.remove(result.photos.single.id);
      controller.dispose();
      await result.photos.single.dispose();
      expect(releases, [bad.path, good.path]);
      await expectLater(XFile(good.path).readAsBytes(), throwsA(anything));
      expect(result.photos.single.bytes, isEmpty);
      expect(
        result.photos.single.cleanupStatus,
        EvidenceCleanupStatus.completed,
      );
    }
  });
  test(
    'Chrome WAV validation, Blob ownership, playback, seek and reader cleanup',
    () async {
      const samples = 8000;
      final wav = ByteData(44 + samples * 2);
      void text(int offset, String value) {
        for (var i = 0; i < value.length; i++) {
          wav.setUint8(offset + i, value.codeUnitAt(i));
        }
      }

      text(0, 'RIFF');
      wav.setUint32(4, wav.lengthInBytes - 8, Endian.little);
      text(8, 'WAVEfmt ');
      wav.setUint32(16, 16, Endian.little);
      wav.setUint16(20, 1, Endian.little);
      wav.setUint16(22, 1, Endian.little);
      wav.setUint32(24, 8000, Endian.little);
      wav.setUint32(28, 16000, Endian.little);
      wav.setUint16(32, 2, Endian.little);
      wav.setUint16(34, 16, Endian.little);
      text(36, 'data');
      wav.setUint32(40, samples * 2, Endian.little);
      final raw = createEvidenceBlob(
        wav.buffer.asUint8List(),
        'audio/wav',
        'misleading.m4a',
      );
      final model = await saveEvidenceAudio(raw);
      releaseEvidenceBlob(raw);
      expect(model.mimeType, 'audio/wav');
      expect(model.fileName, 'recording.wav');
      expect(model.duration, const Duration(seconds: 1));
      final session = EvidencePlayerSession.acquire(
        model,
        () => evidenceMediaPlayer(model.file),
      );
      final player = session.player;
      await session.ready;
      await player.setVolume(0);
      await player.play();
      await player.pause();
      await player.seekTo(const Duration(milliseconds: 500));
      expect(player.value.position, const Duration(milliseconds: 500));
      var deleted = false;
      final deletion = model.dispose().then((_) => deleted = true);
      await Future<void>.delayed(Duration.zero);
      expect(deleted, false);
      session.release();
      await session.released;
      await deletion;
      expect(deleted, true);
      await expectLater(
        XFile(model.file.path).readAsBytes(),
        throwsA(anything),
      );
    },
  );
  test('Chrome MediaRecorder video validates actual duration, WebM, Evidence and fallback', () async {
    final canvas = web.HTMLCanvasElement()
      ..width = 160
      ..height = 90;
    final context = canvas.getContext('2d')! as web.CanvasRenderingContext2D;
    final stream = canvas.captureStream(10);
    final recorder = web.MediaRecorder(
      stream,
      web.MediaRecorderOptions(mimeType: 'video/webm;codecs=vp9'),
    );
    final chunks = <web.Blob>[];
    final stopped = Completer<void>();
    recorder.addEventListener(
      'dataavailable',
      ((web.Event e) {
        chunks.add((e as web.BlobEvent).data);
      }).toJS,
    );
    recorder.addEventListener(
      'stop',
      ((web.Event _) {
        stopped.complete();
      }).toJS,
    );
    recorder.start();
    final timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      context.fillStyle = (timer.tick.isEven ? 'red' : 'blue').toJS;
      context.fillRect(0, 0, 160, 90);
    });
    await Future<void>.delayed(const Duration(milliseconds: 5600));
    recorder.stop();
    await stopped.future;
    timer.cancel();
    for (final track in stream.getTracks().toDart) {
      track.stop();
    }
    final blob = web.Blob(chunks.toJS, web.BlobPropertyBag(type: 'video/webm'));
    final raw = XFile(web.URL.createObjectURL(blob), mimeType: 'video/webm');
    try {
      final model = await saveEvidenceVideo(
        raw,
        const Duration(milliseconds: 5600),
      );
      expect(model.mimeType, 'video/webm');
      expect(model.fileName, 'recording.webm');
      expect(model.duration! >= const Duration(seconds: 5), true);
      final player = evidenceMediaPlayer(model.file);
      await player.initialize();
      expect(player.value.aspectRatio, closeTo(160 / 90, 0.01));
      await player.setVolume(0);
      await player.play();
      await player.pause();
      await player.seekTo(const Duration(seconds: 2));
      expect(player.value.position, const Duration(seconds: 2));
      await player.dispose();
      final container = ProviderContainer();
      expect(
        await evidenceVideoThumbnail(
          model,
          container.read(evidenceThumbnailExtractorProvider),
        ),
        isNull,
      );
      container.dispose();
      final evidence = EvidenceController()..add(model);
      expect(evidence.selected, same(model));
      evidence.remove(model.id);
      await model.dispose();
      expect(evidence.items, isEmpty);
      evidence.dispose();
      await expectLater(
        saveEvidenceVideo(raw, const Duration(seconds: 4)),
        throwsFormatException,
      );
    } finally {
      releaseEvidenceBlob(raw);
    }
  });
}
