import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../models/evidence_model.dart';
import '../widgets/creation/evidence/evidence_camera_cover_preview.dart';
import 'evidence_video_diagnostics.dart';

abstract interface class EvidenceVideoCamera implements Listenable {
  String? get errorDescription;
  Future<void> initialize();
  Widget buildPreview({Widget? overlay});
  Future<void> startRecording();
  Future<XFile> stopRecording();
  Future<void> discardFile(XFile file);
  Future<void> dispose();
}

class DeviceEvidenceVideoCamera extends ChangeNotifier
    implements EvidenceVideoCamera {
  CameraController? _controller;
  Future<void>? _initializing;
  Future<void>? _pending;
  Future<void>? _closing;
  bool _closed = false;
  @override
  String? get errorDescription => _controller?.value.errorDescription;

  @override
  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw CameraException('NoCamera', 'No camera is available.');
    }
    if (_closed) return;
    final camera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
    );
    _controller = controller;
    controller.addListener(_changed);
    await controller.initialize();
  }

  void _changed() {
    if (!_closed) notifyListeners();
  }

  CameraController get _ready {
    final controller = _controller;
    if (_closed || controller == null || !controller.value.isInitialized) {
      throw CameraException('CameraNotReady', 'The camera is not ready.');
    }
    if (_pending != null) {
      throw CameraException('RecordingBusy', 'Wait for the current operation.');
    }
    return controller;
  }

  @override
  Widget buildPreview({Widget? overlay}) {
    final controller = _controller!;
    return ValueListenableBuilder<CameraValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final orientation = value.isRecordingVideo
            ? value.recordingOrientation ?? value.deviceOrientation
            : value.previewPauseOrientation ??
                  value.lockedCaptureOrientation ??
                  value.deviceOrientation;
        final landscape =
            orientation == DeviceOrientation.landscapeLeft ||
            orientation == DeviceOrientation.landscapeRight;
        return EvidenceCameraCoverPreview(
          aspectRatio: landscape ? value.aspectRatio : 1 / value.aspectRatio,
          preview: CameraPreview(controller),
          overlay: overlay,
        );
      },
    );
  }

  @override
  Future<void> startRecording() {
    final controller = _ready;
    if (controller.value.isRecordingVideo) {
      throw CameraException('RecordingBusy', 'Already recording.');
    }
    final operation = controller.startVideoRecording();
    _pending = operation;
    return operation.whenComplete(() => _pending = null);
  }

  @override
  Future<XFile> stopRecording() {
    final controller = _ready;
    final operation = controller.stopVideoRecording();
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation.whenComplete(() => _pending = null);
  }

  @override
  Future<void> discardFile(XFile file) async {
    if (kIsWeb) return;
    final local = File(file.path);
    if (await local.exists()) await local.delete();
  }

  @override
  Future<void> dispose() {
    if (_closing != null) return _closing!;
    _closed = true;
    super.dispose();
    return _closing = _dispose();
  }

  Future<void> _dispose() async {
    _closed = true;
    try {
      await _initializing?.timeout(const Duration(seconds: 5));
    } catch (_) {}
    var pendingFinished = true;
    try {
      await _pending?.timeout(const Duration(seconds: 5));
    } catch (error, stack) {
      pendingFinished = false;
      logRecordVideo('camera pending operation cleanup failed', error, stack);
    }
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      controller.removeListener(_changed);
      try {
        if (pendingFinished && controller.value.isRecordingVideo) {
          final file = await recordVideoStage(
            'cancel stopVideoRecording',
            controller.stopVideoRecording,
            timeout: const Duration(seconds: 5),
            onLateResult: discardFile,
          );
          await recordVideoStage(
            'cancel raw file cleanup',
            () => discardFile(file),
            timeout: const Duration(seconds: 5),
          );
        }
      } finally {
        await recordVideoStage(
          'native camera dispose',
          controller.dispose,
          timeout: const Duration(seconds: 5),
        );
      }
    }
  }
}

typedef EvidenceVideoSaver = Future<EvidenceModel> Function(XFile, Duration);

/// Check the encoded duration as well as the recording UI's monotonic timer.
Future<EvidenceModel> saveEvidenceVideo(
  XFile file,
  Duration elapsed, {
  Duration validationTimeout = const Duration(seconds: 15),
  Duration cleanupTimeout = const Duration(seconds: 5),
}) async {
  if (elapsed < const Duration(seconds: 5)) {
    throw const FormatException('Video is too short.');
  }
  await recordVideoStage('recording file check', () async {
    final size = await file.length();
    logRecordVideo('XFile path=${file.path} bytes=$size');
    if (size == 0) throw const FormatException('The recording file is empty.');
  });
  final player = VideoPlayerController.file(File(file.path));
  late Duration duration;
  try {
    await recordVideoStage(
      'VideoPlayerController.initialize',
      player.initialize,
      timeout: validationTimeout,
    );
    duration = player.value.duration;
    logRecordVideo('encoded duration=${duration.inMilliseconds}ms');
    if (duration < const Duration(seconds: 5)) {
      throw const FormatException('Video is too short.');
    }
  } finally {
    try {
      await recordVideoStage(
        'validation player dispose',
        player.dispose,
        timeout: cleanupTimeout,
      );
    } catch (error, stack) {
      // Creation errors can leave the plugin's creatingCompleter unresolved.
      // Do not let cleanup replace the validation error or wait forever.
      logRecordVideo('validation player cleanup incomplete', error, stack);
    }
  }
  return recordVideoStage(
    'cache copy',
    () => EvidenceModel.fromVideo(file, duration: duration),
    timeout: const Duration(seconds: 15),
    onLateResult: (model) => model.dispose(),
  );
}

String evidenceVideoError(Object error) {
  if (error is TimeoutException) {
    return 'Video processing timed out. Please try again. If it keeps happening, restart the app.';
  }
  if (error is PlatformException && error.code == 'channel-error') {
    return 'Video playback could not be initialized. Fully restart the app and try again.';
  }
  if (error is CameraException) {
    final code = error.code.toLowerCase();
    if (code.contains('audio') &&
        (code.contains('denied') || code.contains('restricted'))) {
      return 'Microphone access was denied. Allow microphone access in your device settings.';
    }
    if (code.contains('denied') || code.contains('restricted')) {
      return 'Camera access was denied. Allow camera access in your device settings.';
    }
    if (code == 'nocamera' || code == 'cameranotfound') {
      return 'No camera was found on this device.';
    }
  }
  if (error is FormatException) {
    if (error.message.contains('short') ||
        error.message.contains('5 seconds')) {
      return 'The video could not be saved. Record at least 5 seconds and try again.';
    }
    return 'The recorded video is empty, unreadable, or incomplete. Please record again.';
  }
  return 'Unable to record or save the video. Please try again.';
}
