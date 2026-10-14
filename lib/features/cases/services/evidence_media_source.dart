import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

enum EvidenceSourceStatus {
  retained,
  cleanupPending,
  nativeReleaseFailed,
  cleanupFailed,
  released,
}

/// Private capture/probe sources can outlive a Save UI. Every actual reader
/// holds a token; a cleanup request never overrides an outstanding reader.
class EvidenceMediaSourceLease {
  EvidenceMediaSourceLease._(this._source);
  final _Source _source;
  bool _released = false;
  void release() {
    if (_released) return;
    _released = true;
    _source.readers--;
    _source.tryCleanup();
  }
}

class EvidenceMediaSources {
  static final _sources = <String, _Source>{};
  static EvidenceMediaSourceLease retain(XFile file) {
    final source = _sources.putIfAbsent(file.path, () => _Source(file.path));
    if (source.cleanup != null) throw StateError('Source cleanup requested');
    source.readers++;
    return EvidenceMediaSourceLease._(source);
  }

  static Future<void> dispose(XFile file, Future<void> Function() cleanup) {
    final source = _sources.putIfAbsent(file.path, () => _Source(file.path));
    if (source.cleanup == null) {
      source.cleanup = cleanup;
      if (source.status != EvidenceSourceStatus.nativeReleaseFailed) {
        source.status = EvidenceSourceStatus.cleanupPending;
      }
    }
    source.tryCleanup();
    return source.done.future;
  }

  static EvidenceSourceStatus? status(XFile file) =>
      _sources[file.path]?.status;

  static void nativeReleaseFailed(XFile file) {
    final source = _sources.putIfAbsent(file.path, () => _Source(file.path));
    source.status = EvidenceSourceStatus.nativeReleaseFailed;
    debugPrint('[EvidenceValidation] native release failed; source preserved');
  }
}

class _Source {
  _Source(this.path);
  final String path;
  int readers = 0;
  bool cleaning = false;
  EvidenceSourceStatus status = EvidenceSourceStatus.retained;
  Future<void> Function()? cleanup;
  final done = Completer<void>();
  void tryCleanup() {
    if (readers != 0 ||
        cleaning ||
        status == EvidenceSourceStatus.nativeReleaseFailed) {
      return;
    }
    if (cleanup == null) {
      EvidenceMediaSources._sources.remove(path);
      return;
    }
    cleaning = true;
    unawaited(() async {
      try {
        await cleanup!();
        status = EvidenceSourceStatus.released;
        EvidenceMediaSources._sources.remove(path);
        done.complete();
      } catch (error, stack) {
        status = EvidenceSourceStatus.cleanupFailed;
        debugPrint(
          '[EvidenceValidation] source cleanup failed; source retained',
        );
        done.completeError(error, stack);
      }
    }());
    // Native completion may arrive long after the UI has stopped awaiting it.
    unawaited(done.future.catchError((Object _) {}));
  }
}

/// A timed caller does not release the original IO/copy reader. Late results
/// are handled before its lease is returned.
Future<T> evidenceSourceOperation<T>(
  XFile file,
  Future<T> Function() action, {
  Duration timeout = const Duration(seconds: 15),
  Future<void> Function(T)? onLateResult,
}) {
  final lease = EvidenceMediaSources.retain(file);
  var expired = false;
  final original = Future<T>.sync(action);
  unawaited(
    original
        .then(
          (value) async {
            try {
              if (expired && onLateResult != null) await onLateResult(value);
            } finally {
              lease.release();
            }
          },
          onError: (Object _, StackTrace _) {
            lease.release();
          },
        )
        .catchError((Object _) {}),
  );
  return original.timeout(
    timeout,
    onTimeout: () {
      expired = true;
      throw TimeoutException('Media source operation timed out');
    },
  );
}
