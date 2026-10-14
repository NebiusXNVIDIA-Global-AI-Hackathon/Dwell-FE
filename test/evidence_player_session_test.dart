import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dwell/features/cases/models/evidence_model.dart';
import 'package:dwell/features/cases/services/evidence_media_platform.dart';
import 'package:dwell/features/cases/services/evidence_player_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:dwell/features/cases/widgets/creation/evidence/evidence_video_preview.dart';
import 'package:dwell/features/cases/widgets/creation/evidence/evidence_audio_preview.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'helpers/fake_evidence_video_player.dart';

Future<void> finishCleanup(WidgetTester tester, EvidenceModel item) async {
  for (
    var i = 0;
    i < 500 && item.cleanupStatus != EvidenceCleanupStatus.completed;
    i++
  ) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
  }
  expect(item.cleanupStatus, EvidenceCleanupStatus.completed);
}

Future<void> finishRelease(
  WidgetTester tester,
  EvidencePlayerSession session,
) async {
  for (
    var i = 0;
    i < 500 && session.status != EvidencePlayerStatus.closed;
    i++
  ) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
  }
  expect(session.status, EvidencePlayerStatus.closed);
  await session.released;
}

Future<void> finishReaders(WidgetTester tester, EvidenceModel item) async {
  for (var i = 0; i < 500 && item.activeMediaReaders > 0; i++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
  }
  expect(item.activeMediaReaders, 0);
}

void main() {
  late Directory storage;
  late FakeEvidenceVideoPlayer platform;
  late VideoPlayerPlatform previous;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('player-session-test-');
    previous = VideoPlayerPlatform.instance;
    platform = FakeEvidenceVideoPlayer();
    VideoPlayerPlatform.instance = platform;
  });
  tearDown(() async {
    VideoPlayerPlatform.instance = previous;
    // All files are test fixtures; a quarantined fake has no real native reader.
    if (await storage.exists()) await storage.delete(recursive: true);
  });
  Future<EvidenceModel> item(WidgetTester tester, EvidenceType type) async =>
      (await tester.runAsync(() async {
        final raw = await File('${storage.path}/source.mp4').writeAsBytes([
          0,
          0,
          0,
          24,
          102,
          116,
          121,
          112,
          105,
          115,
          111,
          109,
          0,
          0,
          0,
          0,
        ]);
        return type == EvidenceType.audio
            ? EvidenceModel.fromAudio(
                XFile(raw.path),
                duration: const Duration(seconds: 6),
                storageDirectory: storage,
              )
            : EvidenceModel.fromVideo(
                XFile(raw.path),
                duration: const Duration(seconds: 6),
                storageDirectory: storage,
              );
      }))!;
  EvidencePlayerSession open(EvidenceModel item) =>
      EvidencePlayerSession.acquire(item, () => evidenceMediaPlayer(item.file));

  for (final type in [EvidenceType.video, EvidenceType.audio]) {
    testWidgets(
      '$type shares one player and releases only after the last client',
      (tester) async {
        final media = await item(tester, type);
        // Player callbacks are in the guarded plugin zone; flush them explicitly.
        final first = open(media), second = open(media);
        expect(first, same(second));
        await tester.pump();
        await first.ready;
        final play = first.run('play', first.player.play);
        await tester.pump();
        await play;
        first.release();
        expect(media.activeMediaReaders, 1);
        final deleted = media.dispose();
        await tester.pump();
        expect(
          await tester.runAsync(() => File(media.file.path).exists()),
          true,
        );
        second.release();
        await tester.pump();
        await finishRelease(tester, first);
        await finishCleanup(tester, media);
        await deleted;
        expect(platform.creates, 1);
        expect(platform.completedDisposals, 1);
      },
    );

    testWidgets(
      '$type rejected creation returns the source lease despite plugin dispose hang',
      (tester) async {
        platform.creationError = PlatformException(code: 'create-failed');
        final media = await item(tester, type);
        final session = open(media);
        await expectLater(session.ready, throwsA(isA<PlatformException>()));
        await tester.pump();
        await finishRelease(tester, session);
        expect(media.activeMediaReaders, 0);
        expect(platform.creates, 0);
        final deleted = media.dispose();
        await finishCleanup(tester, media);
        await deleted;
        session.release();
      },
    );

    testWidgets(
      '$type unfinished creation preserves source; late success is disposed',
      (tester) async {
        platform.createGate = Completer<void>();
        final media = await item(tester, type);
        final session = open(media);
        final failed = expectLater(
          session.ready,
          throwsA(isA<TimeoutException>()),
        );
        await tester.pump(
          evidencePlayerInitializeTimeout + const Duration(seconds: 1),
        );
        await failed;
        final deferred = expectLater(
          media.dispose(),
          throwsA(isA<TimeoutException>()),
        );
        await tester.pump(
          evidenceReaderReleaseTimeout + const Duration(seconds: 1),
        );
        await deferred;
        expect(media.cleanupStatus, EvidenceCleanupStatus.waitingForReaders);
        expect(
          await tester.runAsync(() => File(media.file.path).exists()),
          true,
        );
        expect(() => open(media), throwsStateError);
        platform.createGate!.complete();
        await tester.pump();
        await tester.pump();
        await finishRelease(tester, session);
        await finishCleanup(tester, media);
        expect(media.activeMediaReaders, 0);
        expect(platform.completedDisposals, 1);
        session.release();
      },
    );

    testWidgets(
      '$type permanently unfinished creation keeps a pending source without blocking deletion requests',
      (tester) async {
        platform.createGate = Completer<void>();
        final media = await item(tester, type);
        final session = open(media);
        final failed = expectLater(
          session.ready,
          throwsA(isA<TimeoutException>()),
        );
        await tester.pump(
          evidencePlayerInitializeTimeout + const Duration(seconds: 1),
        );
        await failed;
        final deferred = expectLater(
          media.dispose(),
          throwsA(isA<TimeoutException>()),
        );
        await tester.pump(
          evidenceReaderReleaseTimeout + const Duration(seconds: 1),
        );
        await deferred;
        expect(session.status, EvidencePlayerStatus.pendingRelease);
        expect(media.cleanupStatus, EvidenceCleanupStatus.waitingForReaders);
        expect(
          await tester.runAsync(() => File(media.file.path).exists()),
          true,
        );
        expect(platform.disposals, 0);
        // Never complete: no native absence is invented and no UI timer remains.
        session.release();
      },
    );
  }

  testWidgets(
    'Allocated decoder without metadata is safely disposed on timeout',
    (tester) async {
      platform.sendInitialized = false;
      final media = await item(tester, EvidenceType.video);
      final session = open(media);
      final failed = expectLater(
        session.ready,
        throwsA(isA<TimeoutException>()),
      );
      await tester.pump(
        evidencePlayerInitializeTimeout + const Duration(seconds: 1),
      );
      await failed;
      await tester.pump();
      await finishRelease(tester, session);
      final deleted = media.dispose();
      await finishCleanup(tester, media);
      await deleted;
      expect(platform.completedDisposals, 1);
    },
  );

  testWidgets(
    'Metadata failure closes an allocated decoder before deleting its source',
    (tester) async {
      platform.initializationError = PlatformException(
        code: 'decode-failed',
        message: 'Unreadable',
      );
      final media = await item(tester, EvidenceType.audio);
      final session = open(media);
      final failed = expectLater(
        session.ready,
        throwsA(isA<PlatformException>()),
      );
      await tester.pump();
      await failed;
      await finishRelease(tester, session);
      final deleted = media.dispose();
      await finishCleanup(tester, media);
      await deleted;
      expect(platform.completedDisposals, 1);
    },
  );

  testWidgets(
    'Rapid same-widget and video-to-audio replacement ignores the old late creation',
    (tester) async {
      final old = await item(tester, EvidenceType.video);
      final next = await item(tester, EvidenceType.video);
      final audio = await item(tester, EvidenceType.audio);
      final gate = Completer<void>();
      platform.createGate = gate;
      Widget view(EvidenceModel media) => ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 400,
              child: media.type == EvidenceType.audio
                  ? EvidenceAudioPreview(evidence: media)
                  : EvidenceVideoPreview(evidence: media),
            ),
          ),
        ),
      );
      await tester.pumpWidget(view(old));
      await tester.pump();
      platform.createGate = null;
      await tester.pumpWidget(view(next));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('evidence-video-content')),
        findsOneWidget,
      );
      await tester.pumpWidget(view(audio));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('evidence-audio-play')), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('evidence-audio-play')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      for (final media in [old, next, audio]) {
        unawaited(media.dispose().catchError((Object _) {}));
        await finishCleanup(tester, media);
      }
      expect(platform.creates, 3);
      expect(platform.completedDisposals, 3);
    },
  );

  testWidgets(
    'Dispose delay retains the source while another item is deleted normally',
    (tester) async {
      final media = await item(tester, EvidenceType.audio);
      final other = await item(tester, EvidenceType.video);
      final session = open(media);
      await tester.pump();
      await session.ready;
      platform.disposeGate = Completer<void>();
      session.release();
      final deferred = expectLater(
        media.dispose(),
        throwsA(isA<TimeoutException>()),
      );
      await tester.pump(
        evidenceReaderReleaseTimeout + const Duration(seconds: 1),
      );
      await deferred;
      expect(session.status, EvidencePlayerStatus.pendingRelease);
      expect(await tester.runAsync(() => File(media.file.path).exists()), true);
      await tester.runAsync(other.dispose);
      expect(other.cleanupStatus, EvidenceCleanupStatus.completed);
      platform.disposeGate!.complete();
      await tester.pump();
      await tester.pump();
      await finishRelease(tester, session);
      await finishCleanup(tester, media);
    },
  );

  testWidgets(
    'Native dispose failure is quarantined, not reported as successful deletion',
    (tester) async {
      final media = await item(tester, EvidenceType.video);
      final session = open(media);
      await tester.pump();
      await session.ready;
      platform.disposalError = PlatformException(code: 'dispose-failed');
      session.release();
      final deferred = expectLater(
        media.dispose(),
        throwsA(isA<TimeoutException>()),
      );
      await tester.pump(
        evidenceReaderReleaseTimeout + const Duration(seconds: 1),
      );
      await deferred;
      // The reader timeout is fake time; the backend failure may still be in
      // the real event queue. Observe that outcome before classifying it.
      for (
        var i = 0;
        i < 500 && session.status != EvidencePlayerStatus.releaseFailed;
        i++
      ) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 2)),
        );
      }
      expect(session.status, EvidencePlayerStatus.releaseFailed);
      expect(media.activeMediaReaders, 1);
      expect(await tester.runAsync(() => File(media.file.path).exists()), true);
    },
  );

  testWidgets(
    'Reentry waits for the old native release without duplicating creation',
    (tester) async {
      final media = await item(tester, EvidenceType.video);
      final old = open(media);
      await tester.pump();
      await old.ready;
      platform.disposeGate = Completer<void>();
      old.release();
      final cancelled = Completer<void>();
      final obtaining = EvidencePlayerSession.obtain(
        media,
        () => evidenceMediaPlayer(media.file),
        cancelled.future,
        () => true,
      );
      await tester.pump();
      expect(platform.createAttempts, 1);
      platform.disposeGate!.complete();
      await finishRelease(tester, old);
      final next = await obtaining;
      await tester.pump();
      await next.ready;
      expect(platform.createAttempts, 2);
      next.release();
      await finishRelease(tester, next);
      final deleted = media.dispose();
      await finishCleanup(tester, media);
      await deleted;
    },
  );

  testWidgets(
    'Closing during creation cancels UI wait but drains late native creation',
    (tester) async {
      platform.createGate = Completer<void>();
      final media = await item(tester, EvidenceType.video);
      final session = open(media);
      final cancelled = expectLater(session.ready, throwsStateError);
      session.release();
      await tester.pump();
      await cancelled;
      expect(media.activeMediaReaders, 1);
      platform.createGate!.complete();
      await tester.pump();
      await tester.pump();
      await finishRelease(tester, session);
      final deleted = media.dispose();
      await finishCleanup(tester, media);
      await deleted;
    },
  );

  testWidgets(
    'Late play completion is drained before dispose so no position timer survives',
    (tester) async {
      final media = await item(tester, EvidenceType.audio);
      final session = open(media);
      await tester.pump();
      await session.ready;
      platform.playGate = Completer<void>();
      final cancelled = expectLater(
        session.run('play', session.player.play),
        throwsStateError,
      );
      await tester.pump();
      session.release();
      await tester.pump();
      await cancelled;
      expect(platform.disposals, 0);
      platform.playGate!.complete();
      await tester.pump();
      await tester.pump();
      await finishRelease(tester, session);
      final deleted = media.dispose();
      await finishCleanup(tester, media);
      await deleted;
    },
  );

  testWidgets(
    'A cancelled progress-control gesture has no unhandled error and still holds its native lease',
    (tester) async {
      final media = await item(tester, EvidenceType.video);
      final session = open(media);
      await tester.pump();
      await session.ready;
      platform.playGate = Completer<void>();
      final play = session.player.play();
      await tester.pump();
      session.release();
      await tester.pump();
      await play;
      expect(media.activeMediaReaders, 1);
      expect(platform.disposals, 0);
      platform.playGate!.complete();
      await finishRelease(tester, session);
      final deleted = media.dispose();
      await finishCleanup(tester, media);
      await deleted;
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Progress-control timeout shows a player error without dropping an unfinished native read',
    (tester) async {
      final media = await item(tester, EvidenceType.video);
      final session = open(media);
      await tester.pump();
      await session.ready;
      platform.playGate = Completer<void>();
      final play = session.player.play();
      await tester.pump(
        evidencePlayerInitializeTimeout + const Duration(seconds: 1),
      );
      await play;
      expect(session.player.value.hasError, true);
      expect(media.activeMediaReaders, 1);
      expect(platform.pauses, greaterThan(0));
      platform.playGate!.complete();
      await finishRelease(tester, session);
      final deleted = media.dispose();
      await finishCleanup(tester, media);
      await deleted;
      expect(tester.takeException(), isNull);
    },
  );
}
