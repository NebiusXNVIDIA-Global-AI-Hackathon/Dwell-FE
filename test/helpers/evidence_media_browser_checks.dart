import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  VideoPlayerPlatform.instance = VideoPlayerPlugin();
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
      final player = evidenceMediaPlayer(model.file);
      model.retainVideo();
      await player.initialize();
      await player.setVolume(0);
      await player.play();
      await player.pause();
      await player.seekTo(const Duration(milliseconds: 500));
      expect(player.value.position, const Duration(milliseconds: 500));
      var deleted = false;
      final deletion = model.dispose().then((_) => deleted = true);
      await Future<void>.delayed(Duration.zero);
      expect(deleted, false);
      await player.dispose();
      model.releaseVideo();
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
