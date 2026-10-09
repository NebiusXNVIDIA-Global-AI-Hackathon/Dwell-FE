import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class FakeEvidenceVideoPlayer extends VideoPlayerPlatform {
  Duration duration = const Duration(seconds: 6);
  Size size = const Size(640, 480);
  Duration position = Duration.zero;
  Object? initializationError;
  Object? platformInitializationError;
  Completer<void>? createGate;
  bool sendInitialized = true;
  int creates = 0;
  int plays = 0;
  int pauses = 0;
  int disposals = 0;
  final streams = <int, StreamController<VideoEvent>>{};

  @override
  Future<void> init() async {
    if (platformInitializationError != null) throw platformInitializationError!;
  }

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    await createGate?.future;
    final id = ++creates;
    streams[id] = StreamController<VideoEvent>();
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    final stream = streams[playerId]!;
    if (initializationError != null) {
      stream.addError(initializationError!);
    } else if (sendInitialized) {
      stream.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: duration,
          size: size,
        ),
      );
    }
    return stream.stream;
  }

  @override
  Future<void> dispose(int playerId) async {
    disposals++;
    await streams[playerId]?.close();
  }

  @override
  Future<void> play(int playerId) async {
    plays++;
  }

  @override
  Future<void> pause(int playerId) async {
    pauses++;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<Duration> getPosition(int playerId) async => position;
  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const ColoredBox(
    key: ValueKey('fake-video-player'),
    color: Color(0xFF000000),
  );
}
