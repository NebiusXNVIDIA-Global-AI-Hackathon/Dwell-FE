import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:web/web.dart' as web;

import 'evidence_media_format.dart';

VideoPlayerController evidenceMediaPlayer(XFile file) =>
    VideoPlayerController.networkUrl(Uri.parse(file.path));
void releaseEvidenceBlob(XFile file) {
  if (file.path.startsWith('blob:')) web.URL.revokeObjectURL(file.path);
}

XFile createEvidenceBlob(Uint8List bytes, String mime, String name) =>
    XFile.fromData(bytes, mimeType: mime, name: name);

Future<({XFile file, Future<void> Function() dispose})> storeEvidenceDocument(
  Uint8List bytes,
  String mime,
  String name, {
  Object? storageDirectory,
}) async {
  final file = createEvidenceBlob(bytes, mime, name);
  return (file: file, dispose: () async => releaseEvidenceBlob(file));
}

Future<void> releasePickedDocument(Uri uri) async {
  if (uri.scheme == 'blob') web.URL.revokeObjectURL(uri.toString());
}

/// Probe the browser decoder, not the UI timer. Chromium streaming WebM can
/// omit Duration; seeking to the end makes the decoder discover its actual end.
Future<XFile> prepareEvidenceMedia(XFile file, {required bool audio}) async {
  var bytes = await file.readAsBytes();
  final format = evidenceMediaFormat(bytes, audio: audio);
  final probeFile = createEvidenceBlob(
    bytes,
    format.mime,
    'probe.${format.extension}',
  );
  final element = web.HTMLVideoElement()
    ..preload = 'auto'
    ..muted = true;
  final done = Completer<double>();
  final subscriptions = <StreamSubscription<web.Event>>[];
  void check(web.Event _) {
    final duration = element.duration;
    if (duration.isFinite && duration > 0 && !done.isCompleted) {
      done.complete(duration);
    }
  }

  subscriptions.add(
    element.onLoadedMetadata.listen((event) {
      check(event);
      if (!done.isCompleted) element.currentTime = 1e10;
    }),
  );
  subscriptions.add(element.onDurationChange.listen(check));
  subscriptions.add(element.onTimeUpdate.listen(check));
  subscriptions.add(
    element.onError.listen((_) {
      if (!done.isCompleted) {
        done.completeError(
          const FormatException('Browser cannot decode the recording.'),
        );
      }
    }),
  );
  try {
    element.src = probeFile.path;
    element.load();
    final seconds = await done.future.timeout(const Duration(seconds: 12));
    debugPrint(
      '[${audio ? 'RecordAudio' : 'RecordVideo'}] browser container=${format.extension} bytes=${bytes.length} decoded duration=${seconds}s',
    );
    if (format.extension == 'webm') bytes = withWebmDuration(bytes, seconds);
    return createEvidenceBlob(
      bytes,
      format.mime,
      'recording.${format.extension}',
    );
  } finally {
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    element.pause();
    element.removeAttribute('src');
    element.load();
    releaseEvidenceBlob(probeFile);
  }
}
