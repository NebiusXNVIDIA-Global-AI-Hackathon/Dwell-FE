import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/evidence_model.dart';
import '../../services/evidence_camera.dart';
import '../../widgets/creation/evidence/evidence_guide_frame.dart';

typedef EvidenceCameraLauncher = Future<EvidenceModel?> Function(BuildContext);
final evidenceCameraLauncherProvider = Provider<EvidenceCameraLauncher>(
  (ref) =>
      (context) => Navigator.of(context).push<EvidenceModel>(
        MaterialPageRoute(builder: (_) => const EvidenceCameraPage()),
      ),
);

class EvidenceCameraPage extends StatefulWidget {
  const EvidenceCameraPage({
    super.key,
    this.cameraFactory,
    this.savePhoto,
    this.discardPhoto,
  });
  final EvidenceCamera Function()? cameraFactory;
  // Test boundary; production validation takes ownership of capture output.
  final Future<EvidenceModel> Function(XFile)? savePhoto;
  final Future<void> Function(XFile)? discardPhoto;
  @override
  State<EvidenceCameraPage> createState() => _EvidenceCameraPageState();
}

class _EvidenceCameraPageState extends State<EvidenceCameraPage>
    with WidgetsBindingObserver {
  EvidenceCamera? _camera;
  bool _initializing = false;
  bool _capturing = false;
  bool _active = true;
  String? _error;
  int _generation = 0;
  EvidenceCameraOperation<dynamic>? _operation;
  bool _releasing = false;
  bool _releaseFailed = false;
  bool _resumeRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    if (_initializing ||
        _releasing ||
        _releaseFailed ||
        !_active ||
        !mounted ||
        _camera != null) {
      return;
    }
    _initializing = true;
    _resumeRequested = false;
    final generation = ++_generation;
    setState(() => _error = null);
    try {
      final camera = (widget.cameraFactory ?? DeviceEvidenceCamera.new)();
      _camera = camera;
      final operation = EvidenceCameraOperation<void>(
        'camera initialize',
        camera.initialize,
        timeout: evidenceCameraInitializeTimeout,
      );
      _operation = operation;
      await operation.result;
      if (!mounted || !_active || generation != _generation) return;
      setState(() {});
    } catch (error, stackTrace) {
      logEvidenceCameraDiagnostic(
        'page initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted && _active && generation == _generation) {
        setState(() => _error = _message(error));
      }
      if (generation == _generation) _releaseCamera();
    } finally {
      _initializing = false;
      if (mounted) {
        setState(() {});
        if (_active && generation != _generation) _initialize();
      }
    }
  }

  String _message(Object error) {
    if (error is TimeoutException) {
      return 'Camera initialization timed out. Wait for camera cleanup before Retry. If it remains unavailable, restart the app.';
    }
    if (error is CameraException) {
      if (error.code == 'CameraBusy') {
        return 'The previous camera session is still closing. Wait and retry, or restart the app.';
      }
      if ([
        'CameraAccessDenied',
        'CameraAccessDeniedWithoutPrompt',
        'CameraAccessRestricted',
        'permissionDenied',
        'NotAllowedError',
        'PermissionDeniedError',
      ].contains(error.code)) {
        return 'Camera access was denied. Allow camera access in your device or browser settings. On web, use HTTPS or localhost.';
      }
      if ([
        'NoCamera',
        'cameraNotFound',
        'NotFoundError',
        'DevicesNotFoundError',
      ].contains(error.code)) {
        return 'No camera was found on this device.';
      }
      if ([
        'cameraNotReadable',
        'NotReadableError',
        'TrackStartError',
      ].contains(error.code)) {
        return 'The camera could not be opened. Close other camera apps or tabs, then try again.';
      }
      if ([
        'cameraOverconstrained',
        'OverconstrainedError',
        'ConstraintNotSatisfiedError',
      ].contains(error.code)) {
        return 'The camera could not start with the requested settings. Please try again.';
      }
      if ([
        'cameraType',
        'cameraSecurity',
        'SecurityError',
      ].contains(error.code)) {
        return 'Camera access is unavailable in this browser context. Use HTTPS or localhost and check browser settings.';
      }
      if (error.code == 'cameraNotSupported') {
        return 'This browser does not support camera access.';
      }
    }
    return 'Unable to use the camera. Check camera access and try again.';
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (camera == null ||
        _initializing ||
        _capturing ||
        _releasing ||
        !_active) {
      return;
    }
    final generation = _generation;
    setState(() {
      _capturing = true;
      _error = null;
    });
    try {
      final capture = EvidenceCameraOperation<XFile>(
        'photo capture',
        camera.takePicture,
        timeout: evidenceCameraCaptureTimeout,
        onLateResult: widget.discardPhoto ?? discardEvidenceCapture,
      );
      _operation = capture;
      final file = await capture.result;
      if (!mounted || !_active || generation != _generation) {
        await (widget.discardPhoto ?? discardEvidenceCapture)(file);
        return;
      }
      final save = EvidenceCameraOperation<EvidenceModel>(
        'photo validation',
        () => (widget.savePhoto ?? EvidenceModel.fromCapture)(file),
        timeout: const Duration(seconds: 30),
        onLateResult: (item) => item.dispose(),
      );
      _operation = save;
      final evidence = await save.result;
      if (mounted && _active && generation == _generation) {
        Navigator.of(context).pop(evidence);
      } else {
        await evidence.dispose();
      }
    } catch (error) {
      if (mounted && _active && generation == _generation) {
        setState(
          () => _error = error is TimeoutException
              ? 'Photo capture timed out. Wait for camera cleanup before Retry. If it remains unavailable, restart the app.'
              : 'The photo could not be captured. Please try again.',
        );
        if (error is TimeoutException) _releaseCamera();
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _releaseCamera() {
    final camera = _camera;
    _camera = null;
    if (camera != null) {
      final pending = _operation;
      pending?.abandon();
      _releasing = true;
      // Quarantine follows ORIGINAL completion, not the timed UI result. Never
      // create another controller while native completion/release is unknown.
      unawaited(() async {
        try {
          if (camera is DeviceEvidenceCamera) {
            try {
              await camera.dispose();
            } on TimeoutException {
              logEvidenceCameraDiagnostic(
                'camera release UI timeout; native release pending',
              );
            }
            await camera.released;
          } else {
            if (pending != null && !pending.finished) await pending.settled;
            await camera.dispose();
          }
        } catch (_) {
          _releaseFailed = true;
          if (mounted) _error = 'Camera cleanup could not be confirmed. Restart the app before taking another photo.';
        } finally {
          _releasing = false;
          if (mounted) {
            setState(() {});
            if (_active &&
                !_initializing &&
                !_releaseFailed &&
                _resumeRequested) {
              _initialize();
            }
          }
        }
      }());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logEvidenceCameraDiagnostic('lifecycle=${state.name}');
    _active = state == AppLifecycleState.resumed;
    if (!_active) {
      if (_camera != null) {
        _resumeRequested = true;
        _error ??= 'Camera work was interrupted. Wait for camera cleanup before Retry. If it remains unavailable, restart the app.';
      }
      _generation++;
      _releaseCamera();
      if (mounted) setState(() {});
    } else {
      _initialize();
    }
  }

  @override
  void dispose() {
    _active = false;
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    _releaseCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Semantics(
                  label: 'Back',
                  button: true,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Container(
                        width: 33,
                        height: 33,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white54),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.chevronLeft,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                const Expanded(
                  child: Text(
                    'Take Photo',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_camera != null && !_initializing)
                  Center(
                    child: _camera!.buildPreview(
                      overlay: _error == null
                          ? IgnorePointer(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 36,
                                    ),
                                    child: CustomPaint(
                                      painter: EvidenceGuideFramePainter(),
                                    ),
                                  ),
                                  Center(
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 40,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'Make sure the problem area is clearly in view',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                  ),
                if (_initializing)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                if (_error != null)
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed:
                                _capturing ||
                                    _initializing ||
                                    _releasing ||
                                    _releaseFailed
                                ? null
                                : _camera == null
                                ? _initialize
                                : () => setState(() => _error = null),
                            child: const Text(
                              'Retry',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: SizedBox(
              width: 72,
              height: 72,
              child: FilledButton(
                key: const ValueKey('camera-shutter'),
                onPressed:
                    _camera != null &&
                        !_initializing &&
                        !_capturing &&
                        !_releasing &&
                        _active
                    ? _capture
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white38,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),
                child: _capturing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.black),
                      )
                    : const Icon(LucideIcons.camera300, size: 32),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
