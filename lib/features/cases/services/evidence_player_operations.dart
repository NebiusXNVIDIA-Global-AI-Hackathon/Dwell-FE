import 'package:video_player/video_player.dart';

/// Covers calls made by VideoProgressIndicator as well as our own controls.
/// Their original Futures must settle before disposal: a late play otherwise
/// starts the plugin's position timer after its earlier dispose cancelled it.
mixin EvidencePlayerOperations on VideoPlayerController {
  Future<void> pauseForRelease() => super.pause();
  Future<void> Function(String, Future<void> Function())? trackOperation;
  Future<void> _tracked(String stage, Future<void> Function() action) =>
      trackOperation?.call(stage, action) ?? action();
  @override
  Future<void> play() => _tracked('native play', super.play);
  @override
  Future<void> pause() => _tracked('native pause', super.pause);
  @override
  Future<void> seekTo(Duration position) =>
      _tracked('native seek', () => super.seekTo(position));
}
