import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../../../models/evidence_model.dart';
import '../../../services/evidence_media_platform.dart';
import '../../../services/evidence_player_session.dart';

typedef EvidenceVideoPlayerFactory = VideoPlayerController Function(
  EvidenceModel,
);
final evidenceVideoPlayerFactoryProvider = Provider<EvidenceVideoPlayerFactory>(
  (ref) =>
      (evidence) => evidenceMediaPlayer(evidence.file),
);

class EvidenceVideoPreview extends ConsumerStatefulWidget {
  const EvidenceVideoPreview({
    super.key,
    required this.evidence,
    this.active = true,
  });
  final EvidenceModel evidence;
  final bool active;
  @override
  ConsumerState<EvidenceVideoPreview> createState() =>
      _EvidenceVideoPreviewState();
}

class _EvidenceVideoPreviewState extends ConsumerState<EvidenceVideoPreview>
    with WidgetsBindingObserver {
  VideoPlayerController? _player;
  bool _ready = false;
  bool _busy = false;
  bool _error = false;
  bool _active = true;
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
      final factory = ref.read(evidenceVideoPlayerFactoryProvider);
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

  @override
  void didUpdateWidget(covariant EvidenceVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.evidence, widget.evidence)) {
      _acquisitionCancelled?.complete();
      _acquisitionCancelled = null;
      ++_generation;
      _player?.removeListener(_changed);
      _session?.release();
      _session = null;
      _player = null;
      _ready = _busy = _error = false;
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

  String _time(Duration value) =>
      '${value.inMinutes.toString().padLeft(2, '0')}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final player = _player;
    final ratio = _ready && player != null ? player.value.aspectRatio : 4 / 3;
    // Portrait media stays fully visible in a bounded card with side margins.
    // Landscape and square cards follow decoded metadata, never file names.
    final cardRatio = ratio >= 1 && ratio.isFinite ? ratio : 4 / 3;
    return AspectRatio(
      aspectRatio: cardRatio,
      child: ColoredBox(
        color: Colors.black,
        child: _error
            ? const Center(
                child: Text(
                  'Unable to play this video',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : !_ready || player == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  Positioned.fill(
                    child: Center(
                      child: AspectRatio(
                        key: const ValueKey('evidence-video-content'),
                        aspectRatio: ratio,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: ratio * 1000,
                            height: 1000,
                            child: VideoPlayer(player),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ColoredBox(
                      color: Colors.black54,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            IconButton(
                              key: const ValueKey('evidence-video-play'),
                              tooltip: player.value.isPlaying
                                  ? 'Pause video'
                                  : 'Play video',
                              onPressed: _busy || !widget.active || !_active
                                  ? null
                                  : _toggle,
                              icon: Icon(
                                player.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            Expanded(
                              child: VideoProgressIndicator(
                                player,
                                allowScrubbing: widget.active && _active,
                                colors: const VideoProgressColors(
                                  playedColor: Colors.white,
                                  bufferedColor: Colors.white54,
                                  backgroundColor: Colors.white38,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_time(player.value.position)} / ${_time(player.value.duration)}',
                              key: const ValueKey('evidence-video-time'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
