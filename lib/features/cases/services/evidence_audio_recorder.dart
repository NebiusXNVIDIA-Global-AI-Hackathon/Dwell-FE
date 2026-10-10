import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';

import '../models/evidence_model.dart';

const evidenceAudioLimit = Duration(minutes: 3);
typedef EvidenceAudioSaver = Future<EvidenceModel> Function(XFile);

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
      if (!await _recorder.isEncoderSupported(AudioEncoder.aacLc)) {
        throw StateError('AAC recording is not supported on this device.');
      }
      final base = await getTemporaryDirectory();
      _directory = await Directory(base.path)
          .createTemp('dwell-audio-capture-');
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 96000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: '${_directory!.path}/capture.m4a',
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
      return XFile(path);
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
  final player = VideoPlayerController.file(File(file.path));
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
  return audioStage(
    'cache copy',
    () => EvidenceModel.fromAudio(
      file,
      duration: duration,
      storageDirectory: storageDirectory,
    ),
    onLateResult: (model) => model.dispose(),
  );
}

String evidenceAudioError(Object error) {
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
