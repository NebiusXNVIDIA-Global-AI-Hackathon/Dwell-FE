import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:dwell/features/cases/controllers/evidence_controller.dart';
import 'package:dwell/features/cases/models/evidence_model.dart';
import 'package:dwell/features/cases/services/evidence_library.dart';
import 'package:dwell/features/cases/services/evidence_media_native.dart';
import 'package:dwell/features/cases/widgets/creation/evidence/evidence_add_sheet.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/case_creation_test_harness.dart';

void main() {
  late Directory storage;
  late Uint8List bytes;
  setUpAll(() async {
    await loadCreationTestFonts();
    bytes = (await rootBundle.load(
      'assets/images/evidence_guide/overall_view.png',
    )).buffer.asUint8List();
  });
  setUp(
    () async => storage = await Directory.systemTemp.createTemp('photo-test-'),
  );
  tearDown(() async {
    if (await storage.exists()) await storage.delete(recursive: true);
  });

  testWidgets(
    'Owned capture survives validation, then deletion is idempotent',
    (tester) async {
      await tester.runAsync(() async {
        final source = await File('${storage.path}/capture.png')
            .writeAsBytes(bytes);
        var releases = 0;
        final item = await EvidenceModel.fromCapture(
          XFile(source.path),
          cleanup: () async {
            releases++;
            await releaseOwnedPhoto(
              XFile(source.path),
              cacheDirectory: storage,
            );
          },
        );
        expect(await source.exists(), true);
        final previewBytes = item.bytes;
        final controller = EvidenceController()..add(item);
        controller.remove(item.id);
        controller.remove(item.id);
        await Future.wait([item.dispose(), item.dispose()]);
        expect(releases, 1);
        expect(await source.exists(), false);
        // Preview decoding uses independent bytes, never the removed file.
        expect(item.bytes, isEmpty);
        expect(previewBytes, bytes);
        final codec = await ui.instantiateImageCodec(previewBytes);
        final frame = await codec.getNextFrame();
        frame.image.dispose();
        codec.dispose();
        controller.dispose();
      });
    },
  );

  testWidgets('Borrowed original and paths outside cache are never deleted', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final original = await File('${storage.path}/original.png')
          .writeAsBytes(bytes);
      final cache = await Directory('${storage.path}/cache').create();
      final item = await EvidenceModel.fromFile(XFile(original.path));
      await item.dispose();
      await releaseOwnedPhoto(XFile(original.path), cacheDirectory: cache);
      expect(await original.readAsBytes(), bytes);
    });
  });

  testWidgets(
    'Mixed selection releases failures and transfers successful copies',
    (tester) async {
      await tester.runAsync(() async {
        final good = await File('${storage.path}/good.png').writeAsBytes(bytes);
        final bad = await File('${storage.path}/bad.png')
            .writeAsBytes([1, 2, 3]);
        final releases = <String>[];
        final picker = DeviceEvidenceLibrary(
          pickImages: () async => [XFile(good.path), XFile(bad.path)],
          releasePhoto: (file) async {
            releases.add(file.path);
            await releaseOwnedPhoto(file, cacheDirectory: storage);
          },
        );
        final result = await picker.pickPhotos();
        expect(result.failedCount, 1);
        expect(result.photos.length, 1);
        expect(releases, [bad.path]);
        expect(await good.exists(), true);
        final controller = EvidenceController()..add(result.photos.single);
        controller.dispose();
        await result.photos.single.dispose();
        expect(await good.exists(), false);
        expect(releases, [bad.path, good.path]);
      });
    },
  );

  testWidgets(
    'Cleanup failure preserves validation error and other item cleanup',
    (tester) async {
      await tester.runAsync(() async {
        await expectLater(
          EvidenceModel.fromFile(
            XFile.fromData(Uint8List.fromList([1])),
            cleanup: () async {
              throw StateError('cleanup failed');
            },
          ),
          throwsFormatException,
        );
        var cleaned = 0;
        final first = await EvidenceModel.fromFile(
          XFile.fromData(bytes),
          cleanup: () async {
            throw StateError('cleanup failed');
          },
        );
        final second = await EvidenceModel.fromFile(
          XFile.fromData(bytes),
          cleanup: () async {
            cleaned++;
          },
        );
        final controller = EvidenceController()
          ..add(first)
          ..add(second);
        controller.select(first.id);
        controller.remove(first.id);
        expect(controller.selected, same(second));
        await expectLater(first.dispose(), throwsStateError);
        controller.remove(second.id);
        await second.dispose();
        expect(first.cleanupStatus, EvidenceCleanupStatus.failed);
        expect(second.cleanupStatus, EvidenceCleanupStatus.completed);
        expect(cleaned, 1);
        expect(controller.items, isEmpty);
        controller.dispose();
      });
    },
  );

  testWidgets('Stalled cleanup is bounded without releasing a resource twice', (
    tester,
  ) async {
    final gate = Completer<void>();
    var releases = 0;
    final item = (await tester.runAsync(
      () => EvidenceModel.fromFile(
        XFile.fromData(bytes),
        cleanup: () {
          releases++;
          return gate.future;
        },
      ),
    ))!;
    final original = item.dispose();
    final pending = expectLater(original, throwsA(isA<TimeoutException>()));
    expect(item.cleanupStatus, EvidenceCleanupStatus.deleting);
    await tester.pump(const Duration(seconds: 6));
    await pending;
    expect(item.cleanupStatus, EvidenceCleanupStatus.pending);
    expect(item.dispose(), same(original));
    expect(releases, 1);
    gate.complete();
    await tester.pump();
    await item.cleanupCompletion;
    expect(item.cleanupStatus, EvidenceCleanupStatus.completed);
  });

  for (final lateFailure in [false, true]) {
    testWidgets(
      'Pending photo cleanup preserves source; late failure=$lateFailure',
      (tester) async {
        final gate = Completer<void>();
        var sourceExists = true;
        final item = (await tester.runAsync(
          () => EvidenceModel.fromFile(
            XFile.fromData(bytes),
            cleanup: () async {
              await gate.future;
              sourceExists = false;
            },
          ),
        ))!;
        final waiting = expectLater(
          item.dispose(),
          throwsA(isA<TimeoutException>()),
        );
        await tester.pump(const Duration(seconds: 6));
        await waiting;
        expect(sourceExists, isTrue);
        expect(item.cleanupStatus, EvidenceCleanupStatus.pending);
        expect(item.bytes, isEmpty);
        if (lateFailure) {
          gate.completeError(StateError('late cleanup failure'));
          await expectLater(item.cleanupCompletion!, throwsStateError);
          expect(item.cleanupStatus, EvidenceCleanupStatus.failed);
          expect(sourceExists, isTrue);
        } else {
          // Leave the native operation unresolved: disposal remains bounded.
          await tester.pump(const Duration(minutes: 1));
          expect(item.cleanupStatus, EvidenceCleanupStatus.pending);
          expect(sourceExists, isTrue);
        }
      },
    );
  }

  testWidgets(
    'Native picker deletes its empty UUID copy directory but keeps cache root',
    (tester) async {
      await tester.runAsync(() async {
        const uuid = '12345678-1234-1234-1234-123456789abc';
        final copyDir = await Directory('${storage.path}/$uuid').create();
        final copy = await File('${copyDir.path}/copy.png').writeAsBytes(bytes);
        await releaseOwnedPhoto(XFile(copy.path), cacheDirectory: storage);
        expect(await copyDir.exists(), false);
        final root = await Directory('${storage.path}/$uuid').create();
        final capture = await File('${root.path}/capture.png')
            .writeAsBytes(bytes);
        await releaseOwnedPhoto(XFile(capture.path), cacheDirectory: root);
        expect(await root.exists(), true);
      });
    },
  );

  testWidgets('Case exit releases attached photos as well as the preview', (
    tester,
  ) async {
    var cleaned = 0;
    final item = (await tester.runAsync(
      () => EvidenceModel.fromFile(
        XFile.fromData(bytes),
        cleanup: () async {
          cleaned++;
        },
      ),
    ))!;
    final h = await CreationHarness.start(
      tester,
      direct: true,
      capturePhoto: (_) async => item,
    );
    await h.toArea();
    await h.choose('Ceiling');
    await h.next();
    await h.tap(find.text('Start Adding Evidence'));
    await h.tap(find.byKey(const ValueKey('evidence-add')));
    await h.tap(find.byKey(const ValueKey(EvidenceSource.photo)));
    expect(find.bySemanticsLabel('Selected photo'), findsOneWidget);
    await h.tap(h.headerBack);
    await h.tap(find.text('Leave'));
    expect(item.isDisposed, true);
    expect(cleaned, 1);
    expect(tester.takeException(), isNull);
  });

  for (final source in [EvidenceSource.photo, EvidenceSource.library]) {
    testWidgets('Late $source result after Case exit is released', (
      tester,
    ) async {
      var cleaned = 0;
      final item = (await tester.runAsync(
        () => EvidenceModel.fromFile(
          XFile.fromData(bytes),
          cleanup: () async {
            cleaned++;
          },
        ),
      ))!;
      final gate = Completer<EvidenceModel?>();
      final libraryGate = Completer<EvidenceLibraryResult>();
      final h = await CreationHarness.start(
        tester,
        direct: true,
        capturePhoto: (_) => gate.future,
        pickLibrary: () => libraryGate.future,
      );
      await h.toArea();
      await h.choose('Ceiling');
      await h.next();
      await h.tap(find.text('Start Adding Evidence'));
      await h.tap(find.byKey(const ValueKey('evidence-add')));
      await h.tap(find.byKey(ValueKey(source)));
      h.router.go('/cases');
      await tester.pumpAndSettle();
      if (source == EvidenceSource.photo) {
        gate.complete(item);
      } else {
        libraryGate.complete(EvidenceLibraryResult([item]));
      }
      await tester.pumpAndSettle();
      expect(item.isDisposed, true);
      await item.dispose();
      expect(cleaned, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
