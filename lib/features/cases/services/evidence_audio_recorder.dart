import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../models/evidence_model.dart';
import 'evidence_media_platform.dart';
import 'evidence_media_source.dart';
import 'evidence_media_validation.dart';

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
  DeviceEvidenceAudioRecorder({AudioRecorder? recorder, this._createDirectory})
    : _recorder = recorder ?? AudioRecorder();
  final AudioRecorder _recorder;
  final Future<Directory> Function()? _createDirectory;
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
        _directory =
            await (_createDirectory?.call() ??
                () async {
                  final base = await getTemporaryDirectory();
                  return Directory(base.path)
                      .createTemp('dwell-audio-capture-');
                }());
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
      // stop() already transferred this output to our guarded source lifetime.
      // cancel() is allowed to delete output in the platform implementation.
      if (_captured == null) {
        try {
          await _recorder.cancel();
        } catch (_) {}
      }
      try {
        await _recorder.dispose();
      } catch (_) {
        final captured = _captured;
        if (captured != null) {
          EvidenceMediaSources.nativeReleaseFailed(captured);
        }
        debugPrint(
          '[EvidenceValidation] recorder release failed; capture retained',
        );
        rethrow;
      }
      Future<void> cleanup() async {
        if (_captured != null) releaseEvidenceBlob(_captured!);
        final directory = _directory;
        if (directory != null && await directory.exists()) {
          await directory.delete(recursive: true);
        }
        _captured = null;
        _directory = null;
      }

      final captured = _captured;
      if (captured == null) {
        await cleanup();
      } else {
        await EvidenceMediaSources.dispose(captured, cleanup);
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
  return validateEvidenceMedia(
    file,
    audio: true,
    validationTimeout: validationTimeout,
    cleanupTimeout: cleanupTimeout,
    store: (source, duration) => EvidenceModel.fromAudio(
      source,
      duration: duration,
      storageDirectory: storageDirectory,
    ),
  );
}

String evidenceAudioError(Object error) {
  if (error is EvidenceMediaReleaseException) {
    return 'Audio cleanup could not be confirmed. Restart the app before recording again.';
  }
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
