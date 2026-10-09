import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:record/record.dart';

import '../../models/evidence_model.dart';
import '../../services/evidence_audio_recorder.dart';
import '../../widgets/creation/evidence/evidence_audio_preview.dart';

final evidenceAudioLauncherProvider =
    Provider<Future<EvidenceModel?> Function(BuildContext)>(
      (ref) =>
          (context) => Navigator.of(context).push<EvidenceModel>(
            MaterialPageRoute(builder: (_) => const EvidenceAudioPage()),
          ),
    );

class EvidenceAudioPage extends StatefulWidget {
  const EvidenceAudioPage({
    super.key,
    this.recorderFactory,
    this.saveAudio,
    this.elapsed,
  });
  final EvidenceAudioRecorder Function()? recorderFactory;
  final EvidenceAudioSaver? saveAudio;
  final Duration Function()? elapsed;
  @override
  State<EvidenceAudioPage> createState() => _EvidenceAudioPageState();
}

class _EvidenceAudioPageState extends State<EvidenceAudioPage>
    with WidgetsBindingObserver {
  EvidenceAudioRecorder? _recorder;
  StreamSubscription<RecordState>? _states;
  EvidenceModel? _result;
  final _watch = Stopwatch();
  Timer? _timer;
  Future<void>? _operation;
  bool _starting = false;
  bool _needsReopen = false;
  bool _busy = false,
      _recording = false,
      _closing = false,
      _canPop = false,
      _active = true;
  int _generation = 0;
  String? _error;
  Duration get _elapsed => widget.elapsed?.call() ?? _watch.elapsed;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _toggle() {
    if (_busy || _closing || !_active || _needsReopen || _result != null) {
      return;
    }
    _operation = _recording ? _stop() : _start();
  }

  Future<void> _start() async {
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    EvidenceAudioRecorder? recorder;
    try {
      recorder = (widget.recorderFactory ?? DeviceEvidenceAudioRecorder.new)();
      _recorder = recorder;
      final allowed = await audioStage(
        'microphone permission',
        recorder.hasPermission,
        timeout: const Duration(seconds: 60),
      );
      if (!mounted || _closing || generation != _generation || !_active) return;
      if (!allowed) {
        _error = 'Microphone access was denied. Allow microphone access in your device settings.';
        return;
      }
      _states = recorder.states.listen(
        (state) {
          if (_recording && !_busy && state != RecordState.record) {
            _interrupt('Recording was interrupted. Please record again.');
          }
        },
        onError: (Object error) {
          _interrupt(evidenceAudioError(error));
        },
      );
      _starting = true;
      await audioStage('recording start', recorder.start);
      if (!mounted || _closing || generation != _generation || !_active) return;
      _watch
        ..reset()
        ..start();
      _recording = true;
      _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted || !_recording) return;
        if (_elapsed >= evidenceAudioLimit) {
          _toggle();
        } else {
          setState(() {});
        }
      });
    } catch (error) {
      if (error is TimeoutException) _needsReopen = true;
      if (mounted && generation == _generation) {
        _error = evidenceAudioError(error);
      }
    } finally {
      _starting = false;
      if (!_recording && recorder != null) await _releaseRecorder(recorder);
      _busy = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _stop() async {
    final recorder = _recorder!;
    final generation = _generation;
    _timer?.cancel();
    _watch.stop();
    setState(() => _busy = true);
    EvidenceModel? result;
    try {
      final file = await audioStage('recording stop', recorder.stop);
      _recording = false;
      if (!mounted || _closing || generation != _generation) return;
      result = await audioStage<EvidenceModel>(
        'validate and save',
        () => (widget.saveAudio ?? saveEvidenceAudio)(file),
        timeout: const Duration(seconds: 45),
        onLateResult: (item) => item.dispose(),
      );
      if (!mounted || _closing || generation != _generation || !_active) {
        await result.dispose();
        result = null;
        return;
      }
      _result = result;
    } catch (error) {
      if (error is TimeoutException) _needsReopen = true;
      if (mounted && generation == _generation) {
        _error = evidenceAudioError(error);
      }
      if (result != null && result != _result) await result.dispose();
    } finally {
      _recording = false;
      await _releaseRecorder(recorder);
      _busy = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _releaseRecorder(EvidenceAudioRecorder recorder) async {
    if (_recorder == recorder) _recorder = null;
    final states = _states;
    _states = null;
    try {
      await states?.cancel().timeout(const Duration(seconds: 2));
    } catch (_) {}
    try {
      await audioStage(
        'recorder cleanup',
        recorder.dispose,
        timeout: const Duration(seconds: 5),
      );
    } catch (error) {
      if (error is TimeoutException) {
        _needsReopen = true;
        _error = 'Audio cleanup timed out. Please reopen this screen before recording again.';
      }
    }
  }

  void _interrupt(String message) {
    if (_closing) return;
    ++_generation;
    _timer?.cancel();
    _watch.stop();
    _recording = false;
    _error = message;
    final operation = _operation;
    final recorder = _recorder;
    _busy = true;
    unawaited(() async {
      try {
        await operation;
      } catch (_) {}
      if (recorder != null) await _releaseRecorder(recorder);
      _busy = false;
      if (mounted) setState(() {});
    }());
    if (mounted) setState(() {});
  }

  Future<void> _retake() async {
    if (_busy || _closing) return;
    setState(() => _busy = true);
    final result = _result;
    _result = null;
    // Remove its preview before releasing the owned file.
    setState(() {});
    await WidgetsBinding.instance.endOfFrame;
    if (result != null) {
      try {
        await audioStage(
          'retake cleanup',
          result.dispose,
          timeout: const Duration(seconds: 5),
        );
      } catch (_) {}
    }
    _watch.reset();
    _busy = false;
    if (mounted) setState(() {});
  }

  Future<void> _upload() async {
    if (_busy || _closing) return;
    if (_recording) {
      _operation = _stop();
      await _operation;
    }
    final result = _result;
    if (!mounted || _closing || result == null) return;
    _closing = true;
    _result = null;
    setState(() => _canPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(result);
  }

  Future<void> _back() async {
    if (_closing) return;
    _closing = true;
    ++_generation;
    _timer?.cancel();
    _watch.stop();
    final operation = _operation, recorder = _recorder, result = _result;
    _result = null;
    setState(() => _busy = true);
    final cleanup = () async {
      try {
        await operation;
      } catch (_) {}
      if (recorder != null) await _releaseRecorder(recorder);
      if (result != null) await result.dispose();
    }();
    try {
      await audioStage(
        'cancel cleanup',
        () => cleanup,
        timeout: const Duration(seconds: 5),
      );
    } catch (_) {}
    if (!mounted) return;
    setState(() => _canPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (!_active && (_recording || _starting)) {
      _interrupt(
        'Recording was cancelled when the app became inactive. Please record again.',
      );
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ++_generation;
    _closing = true;
    _timer?.cancel();
    _watch.stop();
    final operation = _operation, recorder = _recorder, result = _result;
    unawaited(() async {
      try {
        await operation;
      } catch (_) {}
      if (recorder != null) await _releaseRecorder(recorder);
      if (result != null) {
        try {
          await result.dispose();
        } catch (_) {}
      }
    }());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<EvidenceModel>(
    canPop: _canPop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _back();
    },
    child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: _back,
                    icon: const Icon(LucideIcons.chevronLeft),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Record Audio',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF243B53),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      if (_result case final result?) ...[
                        EvidenceAudioPreview(
                          key: ValueKey(result.id),
                          evidence: result,
                          active: !_busy && _active,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            key: const ValueKey('audio-retake'),
                            onPressed: _busy || _needsReopen ? null : _retake,
                            icon: const Icon(LucideIcons.rotateCcw, size: 20),
                            label: const Text('retake'),
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          height: 170,
                          width: double.infinity,
                          child: EvidenceAudioWave(recorded: _recording),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${evidenceAudioTime(_elapsed > evidenceAudioLimit ? evidenceAudioLimit : _elapsed)} | 3:00',
                          key: const ValueKey('audio-record-time'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5E5E5E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: IconButton(
                            key: const ValueKey('audio-record-toggle'),
                            tooltip: _recording
                                ? 'Stop recording'
                                : 'Start recording',
                            onPressed: _busy || !_active || _needsReopen
                                ? null
                                : _toggle,
                            style: IconButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: _recording
                                  ? RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    )
                                  : const CircleBorder(),
                            ),
                            icon: Icon(
                              _recording ? Icons.stop_rounded : Icons.circle,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 64),
                      const Text(
                        "Speak slowly and clearly. Try mentioning where the issue is, when it started, and whether it's getting worse. If there's a sound, like dripping, hold your phone close to record it too.",
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.25,
                          color: Color(0xFF627381),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  key: const ValueKey('audio-upload'),
                  onPressed:
                      _busy || !_active || (!_recording && _result == null)
                      ? null
                      : _upload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF243B53),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE3E3E3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Upload'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
