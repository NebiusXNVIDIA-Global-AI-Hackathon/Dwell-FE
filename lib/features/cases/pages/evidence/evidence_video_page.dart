import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/evidence_model.dart';
import '../../services/evidence_video_camera.dart';
import '../../services/evidence_video_diagnostics.dart';
import '../../widgets/creation/evidence/evidence_guide_frame.dart';

typedef EvidenceVideoLauncher = Future<EvidenceModel?> Function(BuildContext);
final evidenceVideoLauncherProvider = Provider<EvidenceVideoLauncher>(
  (ref) =>
      (context) => Navigator.of(context).push<EvidenceModel>(
        MaterialPageRoute(builder: (_) => const EvidenceVideoPage()),
      ),
);

class EvidenceVideoPage extends StatefulWidget {
  const EvidenceVideoPage({
    super.key,
    this.cameraFactory,
    this.saveVideo,
    this.elapsed,
  });
  final EvidenceVideoCamera Function()? cameraFactory;
  final EvidenceVideoSaver? saveVideo;
  // Test boundary; production uses a monotonic Stopwatch after native start.
  final Duration Function()? elapsed;
  @override
  State<EvidenceVideoPage> createState() => _EvidenceVideoPageState();
}

class _EvidenceVideoPageState extends State<EvidenceVideoPage>
    with WidgetsBindingObserver {
  EvidenceVideoCamera? _camera;
  final _watch = Stopwatch();
  Timer? _timer;
  Future<void>? _operation;
  Future<void> _release = Future.value();
  bool _busy = false;
  bool _resumeRequested = false;
  bool _ready = false;
  bool _recording = false;
  bool _active = true;
  bool _closing = false;
  bool _canPop = false;
  int _generation = 0;
  String? _error;
  Duration get _elapsed => widget.elapsed?.call() ?? _watch.elapsed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  void _initialize() {
    if (!mounted || !_active || _closing || _busy || _camera != null) return;
    _operation = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _busy = true;
    final generation = ++_generation;
    setState(() => _error = null);
    try {
      await _release;
      if (!mounted || !_active || generation != _generation) return;
      final camera = (widget.cameraFactory ?? DeviceEvidenceVideoCamera.new)();
      _camera = camera;
      await recordVideoStage('camera initialize', camera.initialize);
      if (!mounted || !_active || generation != _generation) return;
      camera.addListener(_cameraChanged);
      setState(() => _ready = true);
      _cameraChanged();
    } catch (error) {
      if (mounted && _active && generation == _generation) {
        _error = evidenceVideoError(error);
        _releaseCamera();
      }
    } finally {
      _busy = false;
      if (mounted) {
        setState(() {});
        _resumeAfterOperation();
      }
    }
  }

  void _cameraChanged() {
    if (_camera?.errorDescription == null || _closing) return;
    _generation++;
    _error = 'The recording was interrupted. Please try again.';
    _releaseCamera();
    if (mounted) setState(() {});
  }

  void _toggleRecording() {
    if (_busy || !_ready || !_active || _closing) return;
    if (_recording && _elapsed < const Duration(seconds: 5)) return;
    logRecordVideo(
      'button pressed recording=$_recording elapsed=${_elapsed.inMilliseconds}ms',
    );
    _operation = _recording ? _stop() : _start();
  }

  Future<void> _start() async {
    final camera = _camera!;
    final generation = _generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await recordVideoStage('startVideoRecording', camera.startRecording);
      if (!mounted || !_active || generation != _generation) return;
      _watch
        ..reset()
        ..start();
      _recording = true;
      _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (mounted && _recording) setState(() {});
      });
    } catch (error) {
      if (mounted && _active && generation == _generation) {
        _error = evidenceVideoError(error);
        _releaseCamera();
      }
    } finally {
      _busy = false;
      if (mounted) {
        setState(() {});
        _resumeAfterOperation();
      }
    }
  }

  Future<void> _stop() async {
    final camera = _camera!;
    final generation = _generation;
    final elapsed = _elapsed;
    _timer?.cancel();
    _watch.stop();
    setState(() => _busy = true);
    EvidenceModel? evidence;
    try {
      final file = await recordVideoStage(
        'stopVideoRecording',
        camera.stopRecording,
        onLateResult: camera.discardFile,
      );
      _recording = false;
      try {
        if (!mounted || !_active || generation != _generation) return;
        evidence = await recordVideoStage<EvidenceModel>(
          'validate and save video',
          () => (widget.saveVideo ?? saveEvidenceVideo)(file, elapsed),
          timeout: const Duration(seconds: 60),
          onLateResult: (model) => model.dispose(),
        );
        if (!mounted || !_active || generation != _generation) {
          await _discardEvidence(evidence);
          evidence = null;
          return;
        }
      } finally {
        try {
          await recordVideoStage(
            'raw file cleanup',
            () => camera.discardFile(file),
            timeout: const Duration(seconds: 5),
          );
        } catch (_) {}
      }
      if (mounted && _active && generation == _generation) {
        _closing = true;
        // Release the camera before returning so a new capture route cannot
        // overlap this route's reverse transition. The native stop is complete.
        _releaseCamera(waitForOperation: false);
        await _release;
        if (!mounted || !_active || generation != _generation) {
          await evidence.dispose();
          evidence = null;
        }
        _canPop = true;
        logRecordVideo('navigation ready, waiting for PopScope frame');
        setState(() {});
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) {
          logRecordVideo('Navigator.pop result=${evidence?.id}');
          Navigator.of(context).pop(evidence);
          logRecordVideo('Navigator.pop invoked');
        }
      } else {
        await evidence.dispose();
      }
    } catch (error, stack) {
      logRecordVideo('completion failed', error, stack);
      if (evidence != null) {
        unawaited(
          evidence.dispose().catchError((Object error) {
            logRecordVideo('failed evidence cleanup', error);
          }),
        );
      }
      if (mounted && _active && generation == _generation) {
        _closing = false;
        _error = evidenceVideoError(error);
        _releaseCamera();
      }
    } finally {
      _busy = false;
      logRecordVideo('completion loading cleared');
      if (mounted) {
        setState(() {});
        _resumeAfterOperation();
      }
    }
  }

  Future<void> _discardEvidence(EvidenceModel evidence) async {
    try {
      await recordVideoStage(
        'cancelled evidence cleanup',
        evidence.dispose,
        timeout: const Duration(seconds: 5),
      );
    } catch (error, stack) {
      logRecordVideo('cancelled evidence cleanup incomplete', error, stack);
    }
  }

  void _resumeAfterOperation() {
    if (_resumeRequested && _active && !_closing && mounted) {
      _resumeRequested = false;
      _initialize();
    }
  }

  void _releaseCamera({bool waitForOperation = true}) {
    final camera = _camera;
    _camera = null;
    _ready = false;
    _recording = false;
    _timer?.cancel();
    _watch
      ..stop()
      ..reset();
    if (camera != null) {
      camera.removeListener(_cameraChanged);
      final pending = waitForOperation ? _operation : null;
      _release = _release.then((_) async {
        try {
          await pending?.timeout(const Duration(seconds: 65));
        } catch (_) {}
        try {
          await recordVideoStage(
            'camera release',
            camera.dispose,
            timeout: const Duration(seconds: 16),
          );
        } catch (_) {}
      });
    }
  }

  Future<void> _cancel() async {
    if (_closing) return;
    _closing = true;
    _active = false;
    _generation++;
    _releaseCamera();
    if (mounted) setState(() {});
    await _release;
    if (!mounted) return;
    setState(() => _canPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (!_active) {
      final interrupted = _recording || _busy;
      _generation++;
      _releaseCamera();
      if (interrupted) _error = 'Recording cancelled when the app became inactive. Please record again.';
      if (mounted) setState(() {});
    } else if (!_closing) {
      _resumeRequested = _busy;
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
  Widget build(BuildContext context) {
    final seconds = _recording ? _elapsed.inSeconds : 0;
    final time =
        "${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}";
    return PopScope<EvidenceModel>(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        tooltip: 'Back',
                        padding: EdgeInsets.zero,
                        onPressed: _closing ? null : _cancel,
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
                    const SizedBox(width: 3),
                    const Expanded(
                      child: Text(
                        'Record Video',
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
                    if (_ready && _camera != null)
                      Center(
                        child: _camera!.buildPreview(
                          overlay: IgnorePointer(
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
                                if (!_recording)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 40,
                                      ),
                                      child: Container(
                                        key: const ValueKey(
                                          'video-instruction',
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'Make sure the problem area\nis clearly in view.\nMinimum 5 seconds.',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_busy || _closing)
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    if (_error != null && !_busy && !_closing)
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
                              TextButton(
                                onPressed: _active ? _initialize : null,
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
              Text(
                time,
                key: const ValueKey('video-time'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              if (_recording && seconds < 5)
                Text(
                  'Record for ${5 - seconds} more seconds',
                  style: const TextStyle(color: Colors.white70),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: FilledButton(
                    key: const ValueKey('video-record'),
                    onPressed:
                        _ready &&
                            !_busy &&
                            _active &&
                            !_closing &&
                            (!_recording ||
                                _elapsed >= const Duration(seconds: 5))
                        ? _toggleRecording
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      disabledBackgroundColor: _recording
                          ? Colors.red.shade800
                          : Colors.white38,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                    ),
                    child: Icon(
                      _recording ? LucideIcons.square : LucideIcons.circle,
                      size: _recording ? 28 : 40,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
