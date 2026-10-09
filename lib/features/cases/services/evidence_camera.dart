import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';

/// Debug-only diagnostics; never log captured files or image bytes.
void logEvidenceCameraDiagnostic(
  String message, {
  Object? error,
  StackTrace? stackTrace,
}) {
  if (!kDebugMode) return;
  debugPrint('[TakePhoto] $message');
  if (error is CameraException) {
    debugPrint(
      '[TakePhoto] code=${error.code} description=${error.description ?? ""}',
    );
  } else if (error != null) {
    debugPrint('[TakePhoto] ${error.runtimeType}: $error');
  }
  if (stackTrace != null) {
    debugPrintStack(label: '[TakePhoto] StackTrace', stackTrace: stackTrace);
  }
}

/// Small hardware boundary used by the real camera page and fake-camera tests.
abstract interface class EvidenceCamera {
  Future<void> initialize();
  Widget buildPreview({Widget? overlay});
  Future<XFile> takePicture();
  Future<void> dispose();
}

class DeviceEvidenceCamera implements EvidenceCamera {
  CameraController? _controller;
  Future<void>? _initializing;
  Future<XFile>? _capture;
  bool _closed = false;
  Future<void>? _closing;

  @override
  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    var stage = 'availableCameras';
    try {
      logEvidenceCameraDiagnostic('availableCameras start');
      final cameras = await availableCameras();
      logEvidenceCameraDiagnostic('availableCameras count=${cameras.length}');
      for (var i = 0; i < cameras.length; i++) {
        final device = cameras[i];
        logEvidenceCameraDiagnostic(
          'camera[$i] name=${device.name} lens=${device.lensDirection.name} orientation=${device.sensorOrientation}',
        );
      }
      if (cameras.isEmpty) {
        throw CameraException('NoCamera', 'No camera is available.');
      }
      if (_closed) return;
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      logEvidenceCameraDiagnostic(
        'selected=${camera.name} lens=${camera.lensDirection.name} resolution=max enableAudio=false',
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.max,
        enableAudio: false,
      );
      _controller = controller;
      stage = 'CameraController.initialize';
      logEvidenceCameraDiagnostic('$stage start');
      await controller.initialize();
      logEvidenceCameraDiagnostic(
        '$stage success previewSize=${controller.value.previewSize}',
      );
    } catch (error) {
      logEvidenceCameraDiagnostic('$stage failed', error: error);
      rethrow; // Preserve the original exception and StackTrace for the page.
    }
  }

  @override
  Widget buildPreview({Widget? overlay}) =>
      CameraPreview(_controller!, child: overlay);

  @override
  Future<XFile> takePicture() {
    if (_closed || _controller == null || !_controller!.value.isInitialized) {
      throw CameraException('CameraNotReady', 'The camera is not ready.');
    }
    if (_capture != null) {
      throw CameraException('CaptureBusy', 'A capture is already running.');
    }
    final capture = _controller!.takePicture();
    _capture = capture;
    return capture.whenComplete(() => _capture = null);
  }

  @override
  Future<void> dispose() => _closing ??= _dispose();
  Future<void> _dispose() async {
    _closed = true;
    // Let outstanding native operations finish before releasing their controller.
    try {
      await _initializing;
    } catch (_) {}
    try {
      await _capture;
    } catch (_) {}
    await _controller?.dispose();
    _controller = null;
  }
}
