import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../../../models/evidence_model.dart';
import '../../../services/evidence_media_platform.dart';
import '../../../services/evidence_player_session.dart';
import 'evidence_audio_amplitude_wave.dart';

final evidenceAudioPlayerFactoryProvider =
    Provider<VideoPlayerController Function(EvidenceModel)>(
      (ref) =>
          (item) => evidenceMediaPlayer(item.file),
    );
String evidenceAudioTime(Duration value) =>
    '${value.inMinutes.toString().padLeft(2, '0')}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';

class EvidenceAudioWave extends StatelessWidget {
  const EvidenceAudioWave({super.key, this.recorded = false});
  final bool recorded;
  @override
  Widget build(BuildContext context) => Semantics(
    label: recorded ? 'Recorded audio' : 'Audio waveform icon',
    child: FittedBox(
      fit: BoxFit.contain,
      child: SvgPicture.asset(
        'assets/icons/case/audio.svg',
        width: 87,
        height: 76,
        excludeFromSemantics: true,
        colorFilter: ColorFilter.mode(const Color(0xFF666666), BlendMode.srcIn),
      ),
    ),
  );
}

class EvidenceAudioPreview extends ConsumerStatefulWidget {
  const EvidenceAudioPreview({
    super.key,
    required this.evidence,
    this.active = true,
  });
  final EvidenceModel evidence;
  final bool active;
  @override
  ConsumerState<EvidenceAudioPreview> createState() =>
      _EvidenceAudioPreviewState();
}

class _EvidenceAudioPreviewState extends ConsumerState<EvidenceAudioPreview>
    with WidgetsBindingObserver {
  VideoPlayerController? _player;
  double? _pendingSeek;
  bool _seeking = false;
  bool _ready = false, _busy = false, _error = false, _active = true;
  EvidencePlayerSession? _session;
  int _generation = 0;
  Completer<void>? _acquisitionCancelled;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    final generation = ++_generation;
    try {
      final evidence = widget.evidence;
      final factory = ref.read(evidenceAudioPlayerFactoryProvider);
      final cancelled = Completer<void>();
      _acquisitionCancelled = cancelled;
      final session = await EvidencePlayerSession.obtain(
        evidence,
        () => factory(evidence),
        cancelled.future,
        () => mounted && generation == _generation,
      );
      if (!mounted || generation != _generation) {
        session.release();
        return;
      }
      _session = session;
      final player = session.player;
      _player = player;
      player.addListener(_changed);
      await session.ready;
      if (player.value.hasError) throw StateError('Playback unavailable.');
      if (mounted && generation == _generation) setState(() => _ready = true);
    } catch (_) {
      if (mounted && generation == _generation) setState(() => _error = true);
    }
  }

  void _changed() {
    if (mounted &&
        (_session?.status == EvidencePlayerStatus.ready ||
            (_player?.value.hasError ?? false))) {
      setState(() => _error = _player?.value.hasError ?? false);
    }
  }

  Future<void> _toggle() async {
    final generation = _generation;
    final player = _player;
    if (!_ready || player == null || _busy || !widget.active || !_active) {
      return;
    }
    setState(() => _busy = true);
    try {
      await _session!.run('toggle', () async {
        if (player.value.isPlaying) {
          await player.pause();
        } else {
          if (player.value.position >= player.value.duration) {
            await player.seekTo(Duration.zero);
          }
          if (mounted &&
              generation == _generation &&
              widget.active &&
              _active) {
            await player.play();
          }
          if (!mounted || !widget.active || !_active) await player.pause();
        }
      });
    } catch (_) {
      if (mounted && generation == _generation) setState(() => _error = true);
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  void _pause() {
    final player = _player;
    if (player != null && _session?.status == EvidencePlayerStatus.ready) {
      unawaited(_session!.run('pause', player.pause).catchError((Object _) {}));
    }
  }

  Future<void> _seek(double fraction) async {
    final generation = _generation;
    final player = _player;
    if (player == null || _busy || !widget.active || !_active) return;
    _pendingSeek = fraction;
    if (_seeking) return;
    _seeking = true;
    try {
      while (mounted &&
          generation == _generation &&
          widget.active &&
          _active &&
          _pendingSeek != null) {
        final target = _pendingSeek!;
        _pendingSeek = null;
        await _session!.run(
          'preview seek',
          () => player.seekTo(
            Duration(
              microseconds: (player.value.duration.inMicroseconds * target)
                  .round(),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted && generation == _generation) setState(() => _error = true);
    } finally {
      if (generation == _generation) {
        _pendingSeek = null;
        _seeking = false;
      }
    }
  }

  @override
  void didUpdateWidget(covariant EvidenceAudioPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.evidence, widget.evidence)) {
      _acquisitionCancelled?.complete();
      _acquisitionCancelled = null;
      ++_generation;
      _player?.removeListener(_changed);
      _session?.release();
      _session = null;
      _player = null;
      _pendingSeek = null;
      _ready = _busy = _error = _seeking = false;
      _initialize();
    }
    if (!widget.active) _pause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (!_active) _pause();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _acquisitionCancelled?.complete();
    _acquisitionCancelled = null;
    ++_generation;
    WidgetsBinding.instance.removeObserver(this);
    final player = _player;
    player?.removeListener(_changed);
    _session?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = _player;
    final duration = player?.value.duration ?? Duration.zero;
    final position = player?.value.position ?? Duration.zero;
    final progress = duration.inMicroseconds > 0
        ? (position.inMicroseconds / duration.inMicroseconds)
              .clamp(0, 1)
              .toDouble()
        : 0.0;
    final hasLevels = widget.evidence.audioLevels.any(
      (level) => level.isFinite,
    );
    return Container(
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
      child: _error
          ? const SizedBox(
              height: 150,
              child: Center(child: Text('Unable to play this audio')),
            )
          : !_ready || player == null
          ? const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: EvidenceAudioAmplitudeWave(
                    levels: widget.evidence.audioLevels,
                    animate: false,
                    playbackLevels: hasLevels
                        ? summarizeEvidenceAudio(
                            widget.evidence.audioLevels,
                            widget.evidence.audioLevelTimes,
                            widget.evidence.audioCaptureDuration ?? duration,
                          )
                        : EvidenceAudioAmplitudeWave.profile
                              .map((v) => v * 0.5)
                              .toList(),
                    progress: progress,
                  ),
                ),
                const SizedBox(height: 12),
                if (!hasLevels)
                  const Text(
                    'Amplitude data unavailable — illustrative waveform',
                    style: TextStyle(fontSize: 12, color: Color(0xFF627381)),
                  ),
                Text(
                  '${evidenceAudioTime(player.value.position)} / ${evidenceAudioTime(player.value.duration)}',
                  key: const ValueKey('evidence-audio-time'),
                  style: const TextStyle(
                    color: Color(0xFF007AFF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      key: const ValueKey('evidence-audio-play'),
                      tooltip: player.value.isPlaying
                          ? 'Pause audio'
                          : 'Play audio',
                      onPressed: _busy || !widget.active || !_active
                          ? null
                          : _toggle,
                      icon: Icon(
                        player.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 32,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        key: const ValueKey('evidence-audio-progress'),
                        value: progress,
                        activeColor: const Color(0xFF1684FF),
                        onChanged:
                            _busy ||
                                !widget.active ||
                                !_active ||
                                duration <= Duration.zero
                            ? null
                            : (value) {
                                unawaited(_seek(value));
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
