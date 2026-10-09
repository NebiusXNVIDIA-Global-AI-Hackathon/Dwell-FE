import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_thumbnail_gen/video_thumbnail_gen.dart';

import '../models/evidence_model.dart';

typedef EvidenceThumbnailExtractor = Future<Uint8List?> Function(
  String path,
  int timeMs,
);
final evidenceThumbnailExtractorProvider = Provider<EvidenceThumbnailExtractor>(
  (ref) =>
      (path, timeMs) => VideoThumbnail.thumbnailData(
        video: path,
        timeMs: timeMs,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 256,
        quality: 80,
      ),
);

final evidenceThumbnailCacheClearerProvider = Provider<Future<void> Function()>(
  (ref) => VideoThumbnail.clearCache,
);

/// Stay within the clip, including short clips from any future input source.
int evidenceThumbnailTime(Duration? duration) {
  final milliseconds = duration?.inMilliseconds ?? 0;
  if (milliseconds <= 0) return 0;
  return milliseconds > 1000 ? 1000 : milliseconds ~/ 2;
}

Future<Uint8List?> evidenceVideoThumbnail(
  EvidenceModel evidence,
  EvidenceThumbnailExtractor extract, {
  Future<void> Function()? clearNativeCache,
}) => evidence.videoThumbnail(
  () => extract(evidence.file.path, evidenceThumbnailTime(evidence.duration)),
  clearNativeCache: clearNativeCache,
);
