import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import '../models/evidence_model.dart';
import '../widgets/creation/evidence/evidence_camera_cover_preview.dart';
import 'evidence_video_diagnostics.dart';
import 'evidence_media_platform.dart';
import 'evidence_media_source.dart';
import 'evidence_media_validation.dart';
import 'evidence_camera_lease.dart';

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
  DeviceEvidenceVideoCamera({
    EvidenceCameraLeaseManager? leaseManager,
    Future<List<CameraDescription>> Function()? enumerate,
    EvidenceCameraControllerFactory? controllerFactory,
  }) : leaseManager = leaseManager ?? EvidenceCameraLeaseManager.instance,
       _enumerate = enumerate ?? availableCameras,
       _controllerFactory = controllerFactory ?? createEvidenceCameraController;
  final EvidenceCameraLeaseManager leaseManager;
  final Future<List<CameraDescription>> Function() _enumerate;
  final EvidenceCameraControllerFactory _controllerFactory;
  EvidenceCameraLease? _lease;
  Future<void> get released => _lease?.released ?? Future.value();
  CameraController? _controller;
  Future<void>? _initializing;
  Object? _initializeError;
  StackTrace? _initializeStack;
  Future<void>? _pending;
  Future<void>? _closing;
  bool _closed = false;
  @override
  String? get errorDescription => _controller?.value.errorDescription;

  @override
  Future<void> initialize() async {
    if (_closed) throw CameraException('CameraClosed', 'Camera is closed');
    _initializing ??= cameraOperationSettled(
      _initialize(),
      onError: (error, stack) {
        _initializeError = error;
        _initializeStack = stack;
      },
    );
    await _initializing;
    if (_initializeError != null) {
      Error.throwWithStackTrace(_initializeError!, _initializeStack!);
    }
  }

  Future<void> _initialize() async {
    if (_closed) throw CameraException('CameraClosed', 'Camera is closed');
    _lease = leaseManager.acquire();
    final cameras = await _enumerate();
    if (cameras.isEmpty) {
      throw CameraException('NoCamera', 'No camera is available.');
    }
    if (_closed) return;
    final camera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final controller = _controllerFactory(camera, ResolutionPreset.high, true);
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
    _pending = cameraOperationSettled(operation);
    return operation.whenComplete(() => _pending = null);
  }

  @override
  Future<XFile> stopRecording() {
    final controller = _ready;
    final operation = controller.stopVideoRecording();
    _pending = cameraOperationSettled(operation);
    return operation.whenComplete(() => _pending = null);
  }

  @override
  Future<void> discardFile(XFile file) =>
      EvidenceMediaSources.dispose(file, () async {
        if (kIsWeb) {
          releaseEvidenceBlob(file);
          return;
        }
        final local = File(file.path);
        if (await local.exists()) await local.delete();
      });

  @override
  Future<void> dispose() {
    if (_closing != null) return _closing!;
    _closed = true;
    super.dispose();
    final lease = _lease;
    return _closing = lease == null ? Future.value() : lease.close(_dispose);
  }

  Future<void> _dispose() async {
    _closed = true;
    try {
      await _initializing;
    } catch (_) {}
    try {
      await _pending;
    } catch (_) {}
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_changed);
      try {
        if (controller.value.isRecordingVideo) {
          final file = await controller.stopVideoRecording();
          // File cleanup has a separate lifetime and must not hold hardware.
          unawaited(
            discardFile(file).catchError((Object _) {
              logRecordVideo('cancel raw file cleanup incomplete');
            }),
          );
        }
      } catch (error, stack) {
        // A returned stop error is not a pending native operation. Disposal
        // still must be confirmed before returning the hardware lease.
        logRecordVideo('cancel recording stop failed', error, stack);
      } finally {
        await controller.dispose();
      }
      _controller = null;
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
  return validateEvidenceMedia(
    file,
    audio: false,
    validationTimeout: validationTimeout,
    cleanupTimeout: cleanupTimeout,
    store: (source, duration) =>
        EvidenceModel.fromVideo(source, duration: duration),
  );
}

String evidenceVideoError(Object error) {
  if (error is EvidenceMediaReleaseException) {
    return 'Video cleanup could not be confirmed. Restart the app before recording again.';
  }
  if (error is TimeoutException) {
    return 'Video processing timed out. Please try again. If it keeps happening, restart the app.';
  }
  if (error is PlatformException && error.code == 'channel-error') {
    return 'Video playback could not be initialized. Fully restart the app and try again.';
  }
  if (error is CameraException) {
    if (error.code == 'CameraBusy') {
      return 'Previous camera cleanup is still pending. Wait and Retry. If it remains unavailable, restart the app.';
    }
    final code = error.code.toLowerCase();
    if (code.contains('notsupported') || code.contains('not_supported')) {
      return 'This browser does not support a usable video recording format. Try another browser.';
    }
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
