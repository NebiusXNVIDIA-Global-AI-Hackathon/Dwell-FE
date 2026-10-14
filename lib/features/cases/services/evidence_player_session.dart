import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../models/evidence_model.dart';
import 'evidence_player_operations.dart';

const evidencePlayerInitializeTimeout = Duration(seconds: 15);
const evidencePlayerReleaseTimeout = Duration(seconds: 5);

enum EvidencePlayerStatus {
  creating,
  initializing,
  ready,
  failed,
  closing,
  pendingRelease,
  releaseFailed,
  closed,
}

// Compatibility boundary for the locked video_player 2.14.1 implementation.
// Its initialize Future includes metadata; isInitialized cannot distinguish a
// rejected allocation from an allocated decoder with missing metadata. Keep
// this single dependency covered by the allocation-failure lifecycle tests.
int _nativePlayerId(VideoPlayerController player) {
  // ignore: invalid_use_of_visible_for_testing_member
  return player.playerId;
}

/// A shared preview lease. UI waits are bounded; native waits retain the source
/// until removal is confirmed. Uses the installed video_player's public id to
/// distinguish a returned creation error from an unfinished creation Future.
class EvidencePlayerSession {
  EvidencePlayerSession._(
    this.evidence,
    VideoPlayerController Function() factory,
  ) : _releaseSource = evidence!.releaseVideo,
      initializeTimeout = evidencePlayerInitializeTimeout {
    evidence!.retainVideo();
    _start(factory);
  }

  /// Validation has no published model yet. Its source lease follows exactly
  /// the same native allocation/release rules as a preview session.
  EvidencePlayerSession.forSource(
    VideoPlayerController Function() factory, {
    required this._releaseSource,
    this.initializeTimeout = evidencePlayerInitializeTimeout,
  }) : evidence = null {
    _start(factory);
  }

  void _start(VideoPlayerController Function() factory) {
    unawaited(_releaseOutcome.future.catchError((Object _) {}));
    try {
      player = factory();
      if (player is EvidencePlayerOperations) {
        (player as EvidencePlayerOperations).trackOperation = _nativeOperation;
      }
      _initializing = _initialize();
    } catch (error) {
      _creationRejected = true;
      _status = EvidencePlayerStatus.failed;
      _releaseLease();
      rethrow;
    }
  }

  static final _sessions = <EvidenceModel, EvidencePlayerSession>{};
  static Future<EvidencePlayerSession> obtain(
    EvidenceModel evidence,
    VideoPlayerController Function() factory,
    Future<void> cancelled,
    bool Function() isCurrent,
  ) async {
    final old = _sessions[evidence];
    if (old != null && old._closing) {
      final barrier = Completer<void>();
      final timer = Timer(evidencePlayerInitializeTimeout, () {
        if (!barrier.isCompleted) {
          barrier.completeError(
            TimeoutException('Previous player release is pending'),
          );
        }
      });
      old.released.then((_) {
        if (!barrier.isCompleted) barrier.complete();
      });
      cancelled.then((_) {
        if (!barrier.isCompleted) {
          barrier.completeError(StateError('Preview closed'));
        }
      });
      try {
        await barrier.future;
      } finally {
        timer.cancel();
      }
    }
    if (!isCurrent()) throw StateError('Preview closed');
    return acquire(evidence, factory);
  }

  static EvidencePlayerSession acquire(
    EvidenceModel evidence,
    VideoPlayerController Function() factory,
  ) {
    final old = _sessions[evidence];
    if (old != null) {
      if (old._closing) throw StateError('Previous player release is pending');
      old._clients++;
      return old;
    }
    final session = EvidencePlayerSession._(evidence, factory);
    _sessions[evidence] = session;
    return session;
  }

  final EvidenceModel? evidence;
  final void Function() _releaseSource;
  final Duration initializeTimeout;
  late final VideoPlayerController player;
  late final Future<void> _initializing;
  Future<void> get ready => _initializing;
  EvidencePlayerStatus _status = EvidencePlayerStatus.creating;
  EvidencePlayerStatus get status =>
      _status == EvidencePlayerStatus.creating && _nativePlayerId(player) >= 0
      ? EvidencePlayerStatus.initializing
      : _status;
  int _clients = 1;
  bool _closing = false, _released = false, _creationRejected = false;
  final _closed = Completer<void>();
  final _releaseOutcome = Completer<void>();
  final _work = <Future<void>>{};
  final _cancelUI = <void Function()>[];

  Future<void> _initialize() async {
    try {
      await _bounded('initialize', () async {
        try {
          await player.initialize();
        } catch (_) {
          // A returned error before an id is assigned is a rejected creation,
          // not a still-running Future. dispose's private completer may hang.
          _creationRejected = _nativePlayerId(player) < 0;
          if (_closing && _creationRejected) _releaseLease();
          rethrow;
        }
        if (player.value.hasError || !player.value.isInitialized) {
          throw StateError('Player is not playable');
        }
      });
      if (_closing) throw StateError('Preview closed');
      _status = EvidencePlayerStatus.ready;
    } catch (error) {
      debugPrint('[EvidencePlayer] initialize failed: ${error.runtimeType}');
      if (!_closing) _status = EvidencePlayerStatus.failed;
      _beginClose();
      rethrow;
    }
  }

  Future<void> run(String stage, Future<void> Function() action) {
    if (_closing) return Future.error(StateError('Preview closed'));
    return _bounded(stage, action);
  }

  Future<void> _nativeOperation(String stage, Future<void> Function() action) {
    // VideoProgressIndicator doesn't await every gesture callback. Ignore a
    // cancelled gesture's UI result, while _work still tracks its original
    // native Future and holds the source until it can safely be disposed.
    if (_closing) return Future.value();
    return _bounded(stage, action).catchError((Object error, StackTrace stack) {
      if (!_closing) {
        _beginClose();
        player.value = VideoPlayerValue.erroneous('Playback unavailable');
      }
    });
  }

  Future<void> _bounded(String stage, Future<void> Function() action) {
    final result = Completer<void>();
    late final Timer timer;
    void cancel() {
      timer.cancel();
      if (!result.isCompleted) {
        result.completeError(StateError('Preview closed'));
      }
    }

    timer = Timer(initializeTimeout, () {
      if (!result.isCompleted) {
        result.completeError(TimeoutException('Player $stage timed out'));
      }
    });
    _cancelUI.add(cancel);
    late final Future<void> settled;
    final original = Completer<void>();
    runZonedGuarded(
      () {
        Future<void>.sync(action).then(
          (_) => original.complete(),
          onError: (Object error, StackTrace stack) =>
              original.completeError(error, stack),
        );
      },
      (error, stack) {
        // An out-of-band plugin error is not proof that creation was rejected.
        if (!result.isCompleted) result.completeError(error, stack);
      },
    );
    settled = original.future
        .then(
          (_) {
            if (!result.isCompleted) result.complete();
          },
          onError: (Object error, StackTrace stack) {
            if (!result.isCompleted) result.completeError(error, stack);
          },
        )
        .whenComplete(() {
          timer.cancel();
          _cancelUI.remove(cancel);
          _work.remove(settled);
        });
    _work.add(settled);
    return result.future;
  }

  void release() {
    if (_clients > 0 && --_clients == 0) _beginClose();
  }

  void _beginClose() {
    if (_closing) return;
    _closing = true;
    _status = EvidencePlayerStatus.closing;
    if (player.value.isInitialized) {
      // Send pause immediately, but don't interpret its UI cancellation as a
      // native acknowledgement. Its original Future joins the release barrier.
      unawaited(
        _bounded(
          'pause for release',
          () => player is EvidencePlayerOperations
              ? (player as EvidencePlayerOperations).pauseForRelease()
              : player.pause(),
        ).catchError((Object _) {}),
      );
    }
    for (final cancel in List.of(_cancelUI)) {
      cancel();
    }
    final timer = Timer(evidencePlayerReleaseTimeout, () {
      if (!_released) {
        _status = EvidencePlayerStatus.pendingRelease;
        debugPrint('[EvidencePlayer] native release pending; source retained');
      }
    });
    unawaited(() async {
      try {
        // Drain original play/seek/initialize work. Late play must not start a
        // position timer after controller disposal (video_player implementation).
        // If creation is rejected, there is no native reader to drain.
        final createdWithoutMetadata =
            _nativePlayerId(player) >= 0 && !player.value.isInitialized;
        if (!_creationRejected && !createdWithoutMetadata) {
          await Future.wait(List.of(_work));
        }
        if (_creationRejected) {
          // No native id exists. Background playback is disabled by the widget
          // rather than the plugin, avoiding its orphan lifecycle observer.
          unawaited(player.dispose().catchError((Object _) {}));
          _releaseLease();
        } else {
          debugPrint('[EvidencePlayer] disposing native');
          await player.dispose();
          debugPrint('[EvidencePlayer] disposed native');
          _releaseLease();
        }
      } catch (_) {
        _status = EvidencePlayerStatus.releaseFailed;
        if (!_releaseOutcome.isCompleted) {
          _releaseOutcome.completeError(
            StateError('Native player release failed'),
          );
        }
        debugPrint('[EvidencePlayer] native release failed; source retained');
      } finally {
        timer.cancel();
      }
    }());
  }

  void _releaseLease() {
    if (_released) return;
    _released = true;
    _releaseSource();
    _status = EvidencePlayerStatus.closed;
    if (identical(_sessions[evidence], this)) _sessions.remove(evidence);
    if (!_closed.isCompleted) _closed.complete();
    if (!_releaseOutcome.isCompleted) _releaseOutcome.complete();
  }

  /// Completes only on confirmed native absence/release, never on a timeout.
  Future<void> get released => _closed.future;

  /// Failure is observable without claiming the source is safe to delete.
  Future<void> get releaseOutcome => _releaseOutcome.future;
}
