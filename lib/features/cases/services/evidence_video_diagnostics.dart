import 'dart:async';

import 'package:flutter/foundation.dart';

void logRecordVideo(String message, [Object? error, StackTrace? stack]) {
  if (!kDebugMode) return;
  debugPrint('[RecordVideo] $message');
  if (error != null) debugPrint('[RecordVideo] $error');
  if (stack != null) debugPrint('[RecordVideo] $stack');
}

/// Bound platform work, including plugin errors raised outside its returned
/// Future. Timeout does not cancel native work; late results must be cleaned up.
Future<T> recordVideoStage<T>(
  String stage,
  Future<T> Function() work, {
  Duration timeout = const Duration(seconds: 20),
  Future<void> Function(T)? onLateResult,
}) async {
  logRecordVideo('$stage begin');
  final result = Completer<T>();
  var abandoned = false;
  runZonedGuarded(
    () async {
      try {
        final value = await work();
        if (abandoned || result.isCompleted) {
          if (onLateResult != null) await onLateResult(value);
        } else {
          result.complete(value);
        }
      } catch (error, stack) {
        if (!result.isCompleted && !abandoned) {
          result.completeError(error, stack);
        } else {
          logRecordVideo('$stage late failure', error, stack);
        }
      }
    },
    (error, stack) {
      logRecordVideo('$stage asynchronous plugin failure', error, stack);
      if (!result.isCompleted && !abandoned) result.completeError(error, stack);
    },
  );
  try {
    final value = await result.future.timeout(timeout);
    logRecordVideo('$stage done');
    return value;
  } catch (error, stack) {
    abandoned = true;
    logRecordVideo('$stage failed', error, stack);
    rethrow;
  }
}
