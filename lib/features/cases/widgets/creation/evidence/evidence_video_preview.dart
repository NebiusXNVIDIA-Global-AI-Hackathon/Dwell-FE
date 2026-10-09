import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../../../models/evidence_model.dart';

typedef EvidenceVideoPlayerFactory = VideoPlayerController Function(
  EvidenceModel,
);
final evidenceVideoPlayerFactoryProvider = Provider<EvidenceVideoPlayerFactory>(
  (ref) =>
      (evidence) => VideoPlayerController.file(File(evidence.file.path)),
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
  bool _retained = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      widget.evidence.retainVideo();
      _retained = true;
      final player = ref.read(evidenceVideoPlayerFactoryProvider)(
        widget.evidence,
      );
      _player = player;
      player.addListener(_changed);
      await player.initialize();
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
      if (player.value.isPlaying) {
        await player.pause();
      } else {
        if (player.value.position >= player.value.duration) {
          await player.seekTo(Duration.zero);
        }
        if (mounted && widget.active && _active) await player.play();
        if (!mounted || !widget.active || !_active) await player.pause();
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _pause() {
    final player = _player;
    if (player != null) unawaited(player.pause().catchError((Object _) {}));
  }

  @override
  void didUpdateWidget(covariant EvidenceVideoPreview oldWidget) {
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
    final evidence = widget.evidence;
    final retained = _retained;
    final player = _player;
    player?.removeListener(_changed);
    unawaited(() async {
      try {
        await player?.dispose();
      } catch (_) {}
      if (retained) evidence.releaseVideo();
    }());
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
