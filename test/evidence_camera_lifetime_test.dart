import 'dart:async';

import 'package:camera/camera.dart';
import 'package:dwell/features/cases/services/evidence_camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Device dispose is bounded but its lease survives until native completion',
    (tester) async {
      final cameras = Completer<List<Object?>>();
      var enumerations = 0;
      const channel = MethodChannel('plugins.flutter.io/camera');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) {
        if (call.method != 'availableCameras') {
          throw StateError('Unexpected native call');
        }
        enumerations++;
        return cameras.future;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final first = DeviceEvidenceCamera();
      Object? initializationError;
      final initializing = first.initialize().catchError((Object error) {
        initializationError = error;
      });
      final closing = expectLater(
        first.dispose(),
        throwsA(isA<TimeoutException>()),
      );
      await tester.pump(
        evidenceCameraReleaseTimeout + const Duration(seconds: 1),
      );
      await closing;
      final second = DeviceEvidenceCamera();
      await expectLater(
        second.initialize(),
        throwsA(
          isA<CameraException>().having(
            (error) => error.code,
            'code',
            'CameraBusy',
          ),
        ),
      );
      await second.dispose();
      expect(enumerations, 1);
      // The original operation is deliberately still alive after UI disposal.
      cameras.complete([]);
      await tester.pump();
      await initializing;
      await first.released;
      expect(initializationError, isA<CameraException>());
      final third = DeviceEvidenceCamera();
      await expectLater(
        third.initialize(),
        throwsA(
          isA<CameraException>().having(
            (error) => error.code,
            'code',
            'NoCamera',
          ),
        ),
      );
      await third.dispose();
      expect(enumerations, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
