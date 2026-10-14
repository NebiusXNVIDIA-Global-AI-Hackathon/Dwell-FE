import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

const evidenceCameraReleaseTimeout = Duration(seconds: 5);

/// A successful completion barrier can cross recordVideoStage's error zones.
/// Awaiting a rejected Future created in another error zone can never settle.
Future<void> cameraOperationSettled(
  Future<dynamic> operation, {
  void Function(Object, StackTrace)? onError,
}) => operation.then<void>(
  (_) {},
  onError: (Object error, StackTrace stack) {
    onError?.call(error, stack);
  },
);
typedef EvidenceCameraControllerFactory = CameraController Function(
  CameraDescription description,
  ResolutionPreset preset,
  bool enableAudio,
);

CameraController createEvidenceCameraController(
  CameraDescription description,
  ResolutionPreset preset,
  bool enableAudio,
) => CameraController(description, preset, enableAudio: enableAudio);

enum EvidenceCameraLeaseStatus {
  active,
  closing,
  pendingRelease,
  releaseFailed,
  released,
}

/// Hardware ownership is independent of captured file ownership. UI timeouts
/// never release a lease; only completion of the ORIGINAL native cleanup does.
class EvidenceCameraLeaseManager {
  static final instance = EvidenceCameraLeaseManager();
  EvidenceCameraLease? _owner;
  int _sequence = 0;
  EvidenceCameraLeaseStatus? get status => _owner?.status;
  EvidenceCameraLease acquire() {
    if (_owner != null) {
      throw CameraException(
        'CameraBusy',
        'Previous camera release is not confirmed. Wait and retry, or restart the app.',
      );
    }
    final lease = EvidenceCameraLease._(this, ++_sequence);
    _owner = lease;
    debugPrint('[EvidenceCamera] session=${lease.id} acquired');
    return lease;
  }

  void _return(EvidenceCameraLease lease) {
    if (identical(_owner, lease)) _owner = null;
  }
}

class EvidenceCameraLease {
  EvidenceCameraLease._(this._manager, this.id);
  final EvidenceCameraLeaseManager _manager;
  final int id;
  EvidenceCameraLeaseStatus status = EvidenceCameraLeaseStatus.active;
  Future<void>? _released;
  Future<void>? _closing;
  Future<void> get released => _released ?? Future.value();

  Future<void> close(Future<void> Function() cleanup) {
    if (_closing != null) return _closing!;
    status = EvidenceCameraLeaseStatus.closing;
    debugPrint('[EvidenceCamera] session=$id native release requested');
    _released = Future<void>.sync(cleanup).then(
      (_) {
        status = EvidenceCameraLeaseStatus.released;
        _manager._return(this);
        debugPrint('[EvidenceCamera] session=$id native release confirmed');
      },
      onError: (Object error, StackTrace stack) {
        status = EvidenceCameraLeaseStatus.releaseFailed;
        debugPrint(
          '[EvidenceCamera] session=$id release failed; lease retained',
        );
        Error.throwWithStackTrace(error, stack);
      },
    );
    unawaited(_released!.catchError((Object _) {}));
    return _closing = _released!.timeout(
      evidenceCameraReleaseTimeout,
      onTimeout: () {
        status = EvidenceCameraLeaseStatus.pendingRelease;
        debugPrint(
          '[EvidenceCamera] session=$id release pending; lease retained',
        );
        throw TimeoutException('Camera release is not confirmed');
      },
    );
  }
}
