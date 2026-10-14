import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../models/evidence_model.dart';
import 'evidence_media_platform.dart';
import 'evidence_media_source.dart';
import 'evidence_player_session.dart';

class EvidenceMediaReleaseException implements Exception {
  const EvidenceMediaReleaseException();
}

/// Both formats validate through the preview's native lifecycle policy. Models
/// are published only after confirmed release and a complete independent copy.
Future<EvidenceModel> validateEvidenceMedia(
  XFile file, {
  required bool audio,
  required Future<EvidenceModel> Function(XFile, Duration) store,
  Duration validationTimeout = const Duration(seconds: 15),
  Duration cleanupTimeout = const Duration(seconds: 5),
  VideoPlayerController Function(XFile)? playerFactory,
  Future<XFile> Function(XFile)? prepare,
  Future<void> Function(XFile)? releasePrepared,
}) async {
  final sourceLease = EvidenceMediaSources.retain(file);
  XFile? prepared;
  EvidencePlayerSession? session;
  try {
    await evidenceSourceOperation(file, () async {
      if (await file.length() <= (audio ? 12 : 0)) {
        throw const FormatException('Empty recording.');
      }
    });
    final validationSource = await evidenceSourceOperation<XFile>(
      file,
      () => prepare?.call(file) ?? prepareEvidenceMedia(file, audio: audio),
      onLateResult: (late) async {
        if (late.path != file.path) {
          await (releasePrepared?.call(late) ??
              Future.sync(() => releaseEvidenceBlob(late)));
        }
      },
    );
    prepared = validationSource;
    final playerLease = EvidenceMediaSources.retain(validationSource);
    session = EvidencePlayerSession.forSource(
      () => (playerFactory ?? evidenceMediaPlayer)(validationSource),
      releaseSource: playerLease.release,
      initializeTimeout: validationTimeout,
    );
    unawaited(
      session.releaseOutcome.catchError((Object _) {
        EvidenceMediaSources.nativeReleaseFailed(validationSource);
      }),
    );
    await session.ready;
    final duration = session.player.value.duration;
    if (session.player.value.hasError ||
        duration <
            (audio
                ? const Duration(microseconds: 1)
                : const Duration(seconds: 5))) {
      throw FormatException(
        audio ? 'The audio is unreadable.' : 'Video is too short.',
      );
    }
    session.release();
    // The timeout aborts publication, but the session still follows disposal.
    try {
      await session.releaseOutcome.timeout(cleanupTimeout);
    } catch (_) {
      if (session.status == EvidencePlayerStatus.releaseFailed) {
        throw const EvidenceMediaReleaseException();
      }
      rethrow;
    }
    debugPrint(
      '[EvidenceValidation] native release confirmed; copying evidence',
    );
    return await evidenceSourceOperation(
      validationSource,
      () => store(validationSource, duration),
      onLateResult: (model) => model.dispose(),
    );
  } finally {
    session?.release();
    if (prepared != null && prepared.path != file.path) {
      final source = prepared;
      unawaited(
        EvidenceMediaSources.dispose(
          source,
          () =>
              releasePrepared?.call(source) ??
              Future.sync(() => releaseEvidenceBlob(source)),
        ).catchError((Object _) {}),
      );
    }
    sourceLease.release();
  }
}
