import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../models/evidence_model.dart';
import 'evidence_media_platform.dart';

const evidenceAudioLimit = Duration(minutes: 3);
typedef EvidenceAudioSaver = Future<EvidenceModel> Function(XFile);

Future<AudioEncoder> selectEvidenceAudioEncoder(
  Future<bool> Function(AudioEncoder) supported, {
  required bool browser,
}) async {
  final candidates = browser
      ? [AudioEncoder.opus, AudioEncoder.aacLc, AudioEncoder.wav]
      : [AudioEncoder.aacLc];
  for (final candidate in candidates) {
    if (await supported(candidate)) return candidate;
  }
  throw UnsupportedError('No supported microphone recording format.');
}

/// A bounded UI wait does not cancel native work. Dispose late results explicitly.
Future<T> audioStage<T>(
  String name,
  Future<T> Function() action, {
  Duration timeout = const Duration(seconds: 15),
  Future<void> Function(T)? onLateResult,
}) async {
  debugPrint('[RecordAudio] $name begin');
  var expired = false;
  final work = action();
  unawaited(
    work.then((value) async {
      if (expired && onLateResult != null) {
        try {
          await onLateResult(value);
        } catch (_) {}
      }
    }, onError: (Object _, StackTrace _) {}),
  );
  try {
    final result = await work.timeout(
      timeout,
      onTimeout: () {
        expired = true;
        throw TimeoutException('$name timed out');
      },
    );
    debugPrint('[RecordAudio] $name done');
    return result;
  } catch (error, stack) {
    debugPrint('[RecordAudio] $name failed: $error\n$stack');
    rethrow;
  }
}

abstract class EvidenceAudioRecorder {
  Stream<RecordState> get states;
  Stream<Amplitude> get amplitudes;
  Future<bool> hasPermission();
  Future<void> start();
  Future<XFile> stop();
  Future<void> dispose();
}

class DeviceEvidenceAudioRecorder implements EvidenceAudioRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  Directory? _directory;
  Future<void>? _pending;
  Future<void>? _closing;
  bool _closed = false;
  XFile? _captured;
  @override
  Stream<RecordState> get states => _recorder.onStateChanged();
  @override
  Stream<Amplitude> get amplitudes =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 100));
  @override
  Future<bool> hasPermission() => _recorder.hasPermission();
  @override
  Future<void> start() {
    if (_closed || _pending != null) throw StateError('Recorder unavailable.');
    final work = () async {
      final encoder = await selectEvidenceAudioEncoder(
        _recorder.isEncoderSupported,
        browser: kIsWeb,
      );
      debugPrint('[RecordAudio] selected encoder=$encoder web=$kIsWeb');
      if (!kIsWeb) {
        final base = await getTemporaryDirectory();
        _directory = await Directory(base.path)
            .createTemp('dwell-audio-capture-');
      }
      await _recorder.start(
        RecordConfig(
          encoder: encoder,
          bitRate: 96000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: kIsWeb ? '' : '${_directory!.path}/capture.m4a',
      );
    }();
    _pending = work;
    return work.whenComplete(() => _pending = null);
  }

  @override
  Future<XFile> stop() {
    if (_closed || _pending != null) throw StateError('Recorder unavailable.');
    final work = () async {
      final path = await _recorder.stop();
      if (path == null) throw const FormatException('No recording file.');
      return _captured = XFile(path);
    }();
    _pending = work.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return work.whenComplete(() => _pending = null);
  }

  @override
  Future<void> dispose() {
    if (_closing != null) return _closing!;
    _closed = true;
    return _closing = () async {
      // Wait on the ORIGINAL native operation before deleting its output.
      // The page bounds its wait separately; eventual native completion still
      // reaches cancel/dispose and removes this private capture directory.
      try {
        await _pending;
      } catch (_) {}
      try {
        await _recorder.cancel();
      } catch (_) {}
      try {
        await _recorder.dispose();
      } finally {
        if (_captured != null) releaseEvidenceBlob(_captured!);
        _captured = null;
        final directory = _directory;
        if (directory != null && await directory.exists()) {
          await directory.delete(recursive: true);
        }
      }
    }();
  }
}

Future<EvidenceModel> saveEvidenceAudio(
  XFile file, {
  Directory? storageDirectory,
  Duration validationTimeout = const Duration(seconds: 15),
  Duration cleanupTimeout = const Duration(seconds: 5),
}) async {
  await audioStage('file check', () async {
    if (await file.length() <= 12) {
      throw const FormatException('Empty recording.');
    }
  });
  debugPrint(
    '[RecordAudio] file name=${file.name} mime=${file.mimeType} bytes=${await file.length()}',
  );
  final prepared = await audioStage(
    'container and browser validation',
    () => prepareEvidenceMedia(file, audio: true),
    onLateResult: (item) async {
      if (item != file) releaseEvidenceBlob(item);
    },
  );
  try {
    final player = evidenceMediaPlayer(prepared);
    late Duration duration;
    try {
      await audioStage(
        'playback validation',
        player.initialize,
        timeout: validationTimeout,
      );
      duration = player.value.duration;
      if (player.value.hasError || duration <= Duration.zero) {
        throw const FormatException('The audio is unreadable.');
      }
    } finally {
      try {
        await audioStage(
          'validation player dispose',
          player.dispose,
          timeout: cleanupTimeout,
        );
      } catch (_) {}
    }
    return await audioStage(
      'cache copy',
      () => EvidenceModel.fromAudio(
        prepared,
        duration: duration,
        storageDirectory: storageDirectory,
      ),
      onLateResult: (model) => model.dispose(),
    );
  } finally {
    if (prepared != file) releaseEvidenceBlob(prepared);
  }
}

String evidenceAudioError(Object error) {
  if (error is UnsupportedError) {
    return 'This browser does not support a usable microphone recording format. Try another browser.';
  }
  if (error is PlatformException &&
      (error.code.toLowerCase().contains('permission') ||
          error.code.toLowerCase().contains('denied'))) {
    return 'Microphone access was denied. Allow microphone access in your device settings.';
  }
  if (error is TimeoutException) {
    return 'Audio processing timed out. Please reopen this screen and try again.';
  }
  if (error is FormatException) {
    return 'The recording is empty, unreadable, or incomplete. Please record again.';
  }
  return 'Unable to record or play audio. Check your microphone and try again.';
}
