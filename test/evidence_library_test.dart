import 'dart:async';

import 'package:dwell/features/cases/models/evidence_model.dart';
import 'package:dwell/features/cases/services/evidence_library.dart';
import 'package:dwell/features/cases/widgets/creation/evidence/evidence_add_sheet.dart';
import 'package:dwell/features/cases/widgets/creation/steps/evidence_step.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/case_creation_test_harness.dart';

late Uint8List bytes;
XFile photo(String name) => XFile.fromData(bytes, name: name, path: name);

Future<CreationHarness> startEvidence(
  WidgetTester tester,
  EvidenceLibraryPicker pick,
) async {
  final h = await CreationHarness.start(
    tester,
    direct: true,
    pickLibrary: pick,
  );
  await h.toArea();
  await h.choose('Ceiling');
  await h.next();
  await h.tap(find.text('Start Adding Evidence'));
  return h;
}

Future<void> openLibrary(CreationHarness h) async {
  await h.tap(find.byKey(const ValueKey('evidence-add')));
  await h.tap(find.byKey(const ValueKey(EvidenceSource.library)));
}

void main() {
  setUpAll(() async {
    await loadCreationTestFonts();
    bytes = (await rootBundle.load(
      'assets/images/evidence_guide/overall_view.png',
    )).buffer.asUint8List();
  });

  testWidgets('Library validates each file and preserves original bytes', (
    tester,
  ) async {
    final library = DeviceEvidenceLibrary(
      pickImages: () async => [
        photo('first.png'),
        XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'unsupported.heic'),
        XFile.fromData(
          Uint8List.fromList([255, 216, 255]),
          name: 'corrupt.jpg',
        ),
        XFile('missing-library-file.png'),
        photo('second.png'),
      ],
    );
    final result = await tester.runAsync(library.pickPhotos);
    expect(result!.photos.length, 2);
    expect(result.failedCount, 3);
    expect(result.photos.first.bytes, orderedEquals(bytes));
    expect(result.photos.first.fileName, 'first.png');
    expect(result.photos.first.mimeType, 'image/png');
    expect(result.photos.first.id, isNot(result.photos.last.id));
    final cancel = await DeviceEvidenceLibrary(pickImages: () async => [])
        .pickPhotos();
    expect(cancel.photos, isEmpty);
    expect(cancel.failedCount, 0);
  });

  test(
    'Library prevents overlapping native calls and unlocks after errors',
    () async {
      final gate = Completer<List<XFile>>();
      var calls = 0;
      final library = DeviceEvidenceLibrary(
        pickImages: () {
          calls++;
          if (calls == 1) return gate.future;
          throw PlatformException(code: 'photo_access_denied');
        },
      );
      final pending = library.pickPhotos();
      expect((await library.pickPhotos()).photos, isEmpty);
      expect(calls, 1);
      gate.complete([]);
      await pending;
      await expectLater(
        library.pickPhotos(),
        throwsA(isA<PlatformException>()),
      );
      await expectLater(
        library.pickPhotos(),
        throwsA(isA<PlatformException>()),
      );
      expect(calls, 3);
    },
  );

  testWidgets(
    'Multiple library photos append, preview, cancel and delete without losing existing evidence',
    (tester) async {
      final photos = await tester.runAsync(
        () async => [
          await EvidenceModel.fromFile(photo('first.png')),
          await EvidenceModel.fromFile(photo('second.png')),
          await EvidenceModel.fromFile(photo('third.png')),
        ],
      );
      var calls = 0;
      final gate = Completer<EvidenceLibraryResult>();
      final h = await startEvidence(tester, () async {
        calls++;
        if (calls == 1) return gate.future;
        if (calls == 2) return EvidenceLibraryResult([photos![2]]);
        return const EvidenceLibraryResult([]);
      });
      final state = tester
          .widget<EvidenceStep>(find.byType(EvidenceStep))
          .evidence!;
      await openLibrary(h);
      final add = tester.widget<EvidenceStep>(find.byType(EvidenceStep)).onAdd;
      add();
      add();
      await tester.pump();
      expect(find.byType(EvidenceAddSheet), findsNothing);
      expect(calls, 1);
      gate.complete(EvidenceLibraryResult(photos!.take(2).toList()));
      await tester.pumpAndSettle();
      expect(state.items.length, 2);
      expect(state.selected, same(photos[1]));
      expect(find.bySemanticsLabel('Selected photo'), findsOneWidget);
      await openLibrary(h);
      expect(state.items, orderedEquals(photos));
      await openLibrary(h);
      expect(state.items, orderedEquals(photos));
      expect(calls, 3);
      await h.tap(find.byKey(ValueKey(photos.first.id)));
      expect(state.selected, same(photos.first));
      await h.tap(find.byTooltip('Delete photo 1'));
      expect(state.items, orderedEquals(photos.skip(1)));
      h.expectStep(5);
      h.expectNext(false);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Permission and partial file errors show feedback and allow retry',
    (tester) async {
      final valid = await tester.runAsync(
        () => EvidenceModel.fromFile(photo('valid.png')),
      );
      var calls = 0;
      final h = await startEvidence(tester, () async {
        if (++calls == 1) throw PlatformException(code: 'photo_access_denied');
        return EvidenceLibraryResult([valid!], failedCount: 1);
      });
      await openLibrary(h);
      final state = tester
          .widget<EvidenceStep>(find.byType(EvidenceStep))
          .evidence!;
      expect(state.items, isEmpty);
      expect(
        find.text(
          evidenceLibraryErrorMessage(
            PlatformException(code: 'photo_access_denied'),
          ),
        ),
        findsOneWidget,
      );
      ScaffoldMessenger.of(tester.element(find.byType(EvidenceStep)))
          .removeCurrentSnackBar();
      await tester.pumpAndSettle();
      await openLibrary(h);
      expect(state.items, [valid]);
      expect(
        find.text(
          'Some photos could not be added. Choose readable JPEG, PNG or WebP photos.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Picker failure messages do not expose file paths or native details',
    () {
      expect(
        evidenceLibraryErrorMessage(MissingPluginException()),
        'Photo selection is unavailable on this device.',
      );
      expect(
        evidenceLibraryErrorMessage(StateError('private path')),
        'Unable to open or read the photo library. Please try again.',
      );
    },
  );
}
