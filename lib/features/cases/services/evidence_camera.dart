import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';

import 'evidence_media_platform.dart';
import 'evidence_camera_lease.dart';
export 'evidence_camera_lease.dart' show evidenceCameraReleaseTimeout;

const evidenceCameraInitializeTimeout = Duration(seconds: 20);
const evidenceCameraCaptureTimeout = Duration(seconds: 15);

/// UI completion and native completion are separate. Abandoning cancels only
/// the UI timer; settled still follows the original work and late cleanup.
class EvidenceCameraOperation<T> {
  EvidenceCameraOperation(
    String stage,
    Future<T> Function() action, {
    required Duration timeout,
    Future<void> Function(T)? onLateResult,
  }) {
    logEvidenceCameraDiagnostic('$stage start');
    _timer = Timer(timeout, () {
      logEvidenceCameraDiagnostic('$stage timeout');
      abandon(TimeoutException('$stage timed out'));
    });
    settled = () async {
      try {
        final value = await action();
        if (_result.isCompleted) {
          if (onLateResult != null) {
            logEvidenceCameraDiagnostic('$stage late result cleanup');
            await onLateResult(value);
          }
        } else {
          _timer.cancel();
          logEvidenceCameraDiagnostic('$stage success');
          _result.complete(value);
        }
      } catch (error) {
        if (!_result.isCompleted) {
          _timer.cancel();
          _result.completeError(error);
        }
        logEvidenceCameraDiagnostic('$stage failed', error: error);
      } finally {
        finished = true;
      }
    }();
  }
  final _result = Completer<T>();
  late final Timer _timer;
  late final Future<void> settled;
  bool finished = false;
  Future<T> get result => _result.future;
  void abandon([Object? error]) {
    _timer.cancel();
    if (!_result.isCompleted) {
      _result.completeError(
        error ?? CameraException('Cancelled', 'Operation cancelled'),
      );
    }
  }
}

Future<void> discardEvidenceCapture(XFile file) async {
  try {
    await releaseOwnedPhoto(file).timeout(evidenceCameraReleaseTimeout);
  } catch (_) {
    logEvidenceCameraDiagnostic('late photo cleanup failed');
  }
}

/// Debug-only diagnostics; never log captured files or image bytes.
void logEvidenceCameraDiagnostic(
  String message, {
  Object? error,
  StackTrace? stackTrace,
}) {
  if (!kDebugMode) return;
  debugPrint('[TakePhoto] $message');
  if (error is CameraException) {
    debugPrint('[TakePhoto] code=${error.code}');
  } else if (error != null) {
    debugPrint('[TakePhoto] ${error.runtimeType}');
  }
  if (stackTrace != null) {
    debugPrintStack(
      label: '[TakePhoto] StackTrace',
      stackTrace: stackTrace,
      maxFrames: 8,
    );
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
  DeviceEvidenceCamera({
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
  CameraController? _controller;
  Future<void>? _initializing;
  Object? _initializeError;
  StackTrace? _initializeStack;
  Future<XFile>? _capture;
  Future<void>? _captureSettled;
  bool _closed = false;
  Future<void>? _closing;
  Future<void>? _released;
  Future<void> get released => _released ?? Future.value();

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
    var stage = 'availableCameras';
    try {
      logEvidenceCameraDiagnostic('availableCameras start');
      final cameras = await _enumerate();
      logEvidenceCameraDiagnostic('availableCameras count=${cameras.length}');
      if (cameras.isEmpty) {
        throw CameraException('NoCamera', 'No camera is available.');
      }
      if (_closed) return;
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      logEvidenceCameraDiagnostic(
        'selected lens=${camera.lensDirection.name} resolution=max enableAudio=false',
      );
      final controller = _controllerFactory(
        camera,
        ResolutionPreset.max,
        false,
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
    _captureSettled = cameraOperationSettled(capture);
    return capture.whenComplete(() => _capture = null);
  }

  @override
  Future<void> dispose() {
    if (_closing != null) return _closing!;
    _closed = true;
    logEvidenceCameraDiagnostic('camera release requested');
    final lease = _lease;
    if (lease == null) return _closing = Future.value();
    _closing = lease.close(_dispose);
    _released = lease.released;
    return _closing!;
  }

  Future<void> _dispose() async {
    _closed = true;
    // Let outstanding native operations finish before releasing their controller.
    try {
      await _initializing;
    } catch (_) {}
    try {
      await _captureSettled;
    } catch (_) {}
    logEvidenceCameraDiagnostic('camera release start');
    try {
      await _controller?.dispose();
      _controller = null;
      logEvidenceCameraDiagnostic('camera release complete');
    } catch (error) {
      // Keep the global lease when native release cannot be confirmed.
      logEvidenceCameraDiagnostic('camera release failed', error: error);
      rethrow;
    }
  }
}
