import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../../../models/evidence_model.dart';
import '../../../services/evidence_audio_recorder.dart';

final evidenceAudioPlayerFactoryProvider =
    Provider<VideoPlayerController Function(EvidenceModel)>(
      (ref) =>
          (item) => VideoPlayerController.file(File(item.file.path)),
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
        colorFilter: ColorFilter.mode(
          recorded ? const Color(0xFF007AFF) : const Color(0xFF5E5E5E),
          BlendMode.srcIn,
        ),
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
  bool _ready = false,
      _busy = false,
      _error = false,
      _active = true,
      _retained = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      widget.evidence.retainVideo(); // Shared owned-file reader lease.
      _retained = true;
      final player = ref.read(evidenceAudioPlayerFactoryProvider)(
        widget.evidence,
      );
      _player = player;
      player.addListener(_changed);
      await audioStage('preview initialize', player.initialize);
      if (player.value.hasError) throw StateError('Playback unavailable.');
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _changed() {
    if (mounted) setState(() => _error = _player?.value.hasError ?? false);
  }

  Future<void> _toggle() async {
    final player = _player;
    if (!_ready || player == null || _busy || !widget.active || !_active) {
      return;
    }
    setState(() => _busy = true);
    try {
      await audioStage('preview toggle', () async {
        if (player.value.isPlaying) {
          await player.pause();
        } else {
          if (player.value.position >= player.value.duration) {
            await player.seekTo(Duration.zero);
          }
          if (mounted && widget.active && _active) await player.play();
          if (!mounted || !widget.active || !_active) await player.pause();
        }
      });
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _pause() {
    final player = _player;
    if (player != null) {
      unawaited(
        audioStage('preview pause', player.pause).catchError((Object _) {}),
      );
    }
  }

  @override
  void didUpdateWidget(covariant EvidenceAudioPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active) _pause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (!_active) _pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final player = _player, evidence = widget.evidence;
    final retained = _retained;
    player?.removeListener(_changed);
    _pause();
    final cleanup = player?.dispose();
    if (cleanup != null) {
      unawaited(
        audioStage(
          'preview dispose',
          () => cleanup,
          timeout: const Duration(seconds: 5),
        ).catchError((Object _) {}),
      );
    }
    unawaited(() async {
      try {
        await cleanup;
      } catch (_) {
      } finally {
        if (retained) evidence.releaseVideo();
      }
    }());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = _player;
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
                const SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: EvidenceAudioWave(recorded: true),
                ),
                const SizedBox(height: 12),
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
                      child: VideoProgressIndicator(
                        player,
                        allowScrubbing: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
