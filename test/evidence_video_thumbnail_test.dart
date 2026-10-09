import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:dwell/features/cases/controllers/evidence_controller.dart';
import 'package:dwell/features/cases/models/evidence_model.dart';
import 'package:dwell/features/cases/services/evidence_video_thumbnail.dart';
import 'package:dwell/features/cases/widgets/creation/evidence/evidence_video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = MethodChannel('plugins.itsxhadi.com/video_thumbnail_gen');
  late Directory storage;
  late EvidenceModel first;
  late EvidenceModel second;
  late Uint8List portrait;
  late Uint8List landscape;
  Future<Uint8List> frame(int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = Colors.orange,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return data!.buffer.asUint8List();
  }

  setUp(() async {
    storage = await Directory.systemTemp.createTemp('video-thumb-test-');
    final file = await File('${storage.path}/source.mp4').writeAsBytes([
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
    first = await EvidenceModel.fromVideo(
      XFile(file.path),
      duration: const Duration(seconds: 6),
      storageDirectory: storage,
    );
    second = await EvidenceModel.fromVideo(
      XFile(file.path),
      duration: const Duration(seconds: 7),
      storageDirectory: storage,
    );
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (await storage.exists()) await storage.delete(recursive: true);
  });
  Future<void> show(WidgetTester tester, EvidenceModel item) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Center(
            child: SizedBox(
              width: 72,
              height: 72,
              child: EvidenceVideoThumbnail(
                key: ValueKey(item.id),
                evidence: item,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> prepare(WidgetTester tester) async {
    portrait = (await tester.runAsync(() => frame(80, 160)))!;
    landscape = (await tester.runAsync(() => frame(160, 80)))!;
  }

  test('Frame time clamps short and unknown durations', () {
    expect(evidenceThumbnailTime(const Duration(seconds: 6)), 1000);
    expect(evidenceThumbnailTime(const Duration(milliseconds: 600)), 300);
    expect(evidenceThumbnailTime(const Duration(milliseconds: 1)), 0);
    expect(evidenceThumbnailTime(Duration.zero), 0);
    expect(evidenceThumbnailTime(null), 0);
  });
  testWidgets(
    'Native request, portrait and landscape cover, and per-video cache survive reentry',
    (tester) async {
      await prepare(tester);
      final calls = <Map<dynamic, dynamic>>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'data') {
              final args = call.arguments as Map<dynamic, dynamic>;
              calls.add(args);
              return args['video'] == first.file.path ? portrait : landscape;
            }
            return null;
          });
      await show(tester, first);
      expect(calls.length, 1);
      expect(calls.first['video'], first.file.path);
      expect(calls.first['timeMs'], 1000);
      expect(calls.first['maxw'], 256);
      expect(calls.first['maxh'], 0);
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.cover);
      expect((image.image as MemoryImage).bytes, portrait);
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
      await show(tester, second);
      expect(calls.length, 2);
      expect(
        (tester.widget<Image>(find.byType(Image)).image as MemoryImage).bytes,
        landscape,
      );
      await show(tester, first);
      expect(calls.length, 2);
      expect(
        (tester.widget<Image>(find.byType(Image)).image as MemoryImage).bytes,
        portrait,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.runAsync(() async {
        await first.dispose();
        await second.dispose();
      });
      await tester.pump();
      expect(
        PaintingBinding.instance.imageCache.containsKey(image.image),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Failure stays a placeholder and is cached', (tester) async {
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'data') {
            calls++;
            throw PlatformException(code: 'CORRUPTED_VIDEO');
          }
          return null;
        });
    await show(tester, first);
    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await show(tester, first);
    expect(calls, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.runAsync(() => first.dispose());
  });
  testWidgets(
    'Concurrent requests share a future; deletion waits for decoder and drops late result',
    (tester) async {
      await prepare(tester);
      await tester.runAsync(() async {
        final gate = Completer<Uint8List?>();
        var calls = 0;
        var clears = 0;
        Future<Uint8List?> extract(String path, int time) {
          calls++;
          return gate.future;
        }

        Future<void> clear() async {
          clears++;
        }

        final a = evidenceVideoThumbnail(
          first,
          extract,
          clearNativeCache: clear,
        );
        final b = evidenceVideoThumbnail(
          first,
          extract,
          clearNativeCache: clear,
        );
        expect(identical(a, b), isTrue);
        expect(calls, 1);
        final state = EvidenceController()
          ..add(first)
          ..add(second);
        state.remove(first.id);
        expect(await File(first.file.path).exists(), isTrue);
        gate.complete(portrait);
        expect(await a, isNull);
        await first.dispose();
        expect(await File(first.file.path).exists(), isFalse);
        expect(clears, greaterThanOrEqualTo(1));
        expect(await evidenceVideoThumbnail(first, extract), isNull);
        expect(calls, 1);
        state.dispose();
        await second.dispose();
        expect(await File(second.file.path).exists(), isFalse);
      });
    },
  );
  testWidgets(
    'Loading placeholder and timeout do not retry or display late frame',
    (tester) async {
      await prepare(tester);
      final gate = Completer<Uint8List?>();
      var calls = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            evidenceThumbnailExtractorProvider.overrideWithValue((_, _) {
              calls++;
              return gate.future;
            }),
          ],
          child: MaterialApp(
            home: SizedBox(
              width: 72,
              height: 72,
              child: EvidenceVideoThumbnail(evidence: first),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Image), findsNothing);
      await tester.pump(const Duration(seconds: 11));
      await tester.pump();
      expect(find.byType(Image), findsNothing);
      expect(calls, 1);
      gate.complete(portrait);
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.runAsync(() => first.dispose());
    },
  );
}
