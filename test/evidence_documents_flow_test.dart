import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dwell/features/cases/models/evidence_model.dart';
import 'package:dwell/features/cases/services/evidence_documents.dart';
import 'package:dwell/features/cases/pages/evidence/evidence_documents_page.dart';
import 'package:dwell/features/cases/widgets/creation/evidence/evidence_add_sheet.dart';
import 'package:dwell/features/cases/widgets/creation/evidence/evidence_document_preview.dart';
import 'package:dwell/features/cases/widgets/creation/steps/evidence_step.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/case_creation_test_harness.dart';
import 'helpers/evidence_document_fixtures.dart';

Future<CreationHarness> openDocuments(
  WidgetTester tester,
  EvidenceDocumentPicker picker, {
  Size size = const Size(393, 844),
  double scale = 1,
}) async {
  final h = await CreationHarness.start(
    tester,
    direct: true,
    pickDocuments: picker,
    size: size,
    textScale: scale,
  );
  await h.toArea();
  await h.choose('Ceiling');
  await h.next();
  await h.tap(find.text('Start Adding Evidence'));
  return h;
}

Future<void> openUpload(CreationHarness h) async {
  await h.tap(find.byKey(const ValueKey('evidence-add')));
  await h.tap(find.byKey(const ValueKey(EvidenceSource.document)));
}

Future<void> pick(WidgetTester tester) async {
  await tester.ensureVisible(
    find.byKey(const ValueKey('document-choose-files')),
  );
  await tester.tap(find.byKey(const ValueKey('document-choose-files')));
  await tester.pump();
}

Future<void> drain(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadCreationTestFonts);
  late Directory storage;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('document-flow-');
  });
  tearDown(() async {
    if (await storage.exists()) await storage.delete(recursive: true);
  });
  Future<EvidenceModel> document(String name, {bool word = false}) =>
      EvidenceModel.fromDocument(
        word ? docxDocument() : pdfDocument(),
        name: name,
        storageDirectory: storage,
      );

  testWidgets(
    'Empty screen, picker cancel, double touches and Back preserve Evidence and Check',
    (tester) async {
      final gate = Completer<EvidenceDocumentResult>();
      var calls = 0;
      final h = await openDocuments(tester, (_) {
        calls++;
        return gate.future;
      });
      final state = tester
          .widget<EvidenceStep>(find.byType(EvidenceStep))
          .evidence!;
      await openUpload(h);
      expect(find.byType(EvidenceDocumentsPage), findsOneWidget);
      expect(find.text('Selected File'), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.byKey(const ValueKey('document-upload')),
            )
            .onPressed,
        isNull,
      );
      expect(calls, 0);
      await pick(tester);
      expect(calls, 1);
      expect(
        tester
            .widget<InkWell>(
              find.byKey(const ValueKey('document-choose-files')),
            )
            .onTap,
        isNull,
      );
      gate.complete(const EvidenceDocumentResult([]));
      await tester.pumpAndSettle();
      expect(state.items, isEmpty);
      await h.tap(find.byTooltip('Back'));
      h.expectNext(false);
    },
  );
  testWidgets(
    'Selected files stage until Upload, remove, partial failures, preserve photo and preview/delete documents',
    (tester) async {
      final first = await tester.runAsync(() => document('Repair Notice.pdf'));
      final second = await tester.runAsync(
        () => document(
          'Very long lease document with many words.docx',
          word: true,
        ),
      );
      var calls = 0;
      final h = await openDocuments(tester, (_) async {
        calls++;
        return calls == 1
            ? EvidenceDocumentResult(
                [first!, second!],
                failures: const ['bad.pdf: The file is empty.'],
              )
            : const EvidenceDocumentResult([]);
      });
      final state = tester
          .widget<EvidenceStep>(find.byType(EvidenceStep))
          .evidence!;
      final bytes = (await rootBundle.load(
        'assets/images/evidence_guide/overall_view.png',
      )).buffer.asUint8List();
      final photo = await tester.runAsync(
        () => EvidenceModel.fromFile(XFile.fromData(bytes, name: 'photo.png')),
      );
      state.add(photo!);
      await tester.pumpAndSettle();
      await openUpload(h);
      await pick(tester);
      await tester.pumpAndSettle();
      expect(find.text('Selected File (2)'), findsOneWidget);
      expect(state.items, [photo]);
      expect(find.textContaining('bad.pdf'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(ValueKey('remove-document-${first!.id}')),
      );
      await tester.tap(find.byKey(ValueKey('remove-document-${first.id}')));
      await drain(tester);
      expect(first.isDisposed, true);
      expect(find.text('Selected File (1)'), findsOneWidget);
      await h.tap(find.byKey(const ValueKey('document-upload')));
      expect(find.byType(EvidenceDocumentsPage), findsNothing);
      expect(state.items, [photo, second]);
      expect(find.byType(EvidenceDocumentPreview), findsOneWidget);
      expect(find.byType(EvidenceDocumentThumbnail), findsOneWidget);
      expect(
        find.byKey(const ValueKey('evidence-document-name')),
        findsOneWidget,
      );
      h.expectNext(false);
      await h.tap(find.byKey(ValueKey(photo.id)));
      expect(find.byType(EvidenceDocumentPreview), findsNothing);
      await h.tap(find.byKey(ValueKey(second!.id)));
      expect(find.byType(EvidenceDocumentPreview), findsOneWidget);
      await h.tap(find.byTooltip('Delete selected evidence'));
      await drain(tester);
      expect(state.items, [photo]);
      expect(second.isDisposed, true);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Back discards staged files and unmount disposes late picker results',
    (tester) async {
      final first = await tester.runAsync(() => document('cancel.pdf'));
      final h = await openDocuments(
        tester,
        (_) async => EvidenceDocumentResult([first!]),
      );
      await openUpload(h);
      await pick(tester);
      await tester.pumpAndSettle();
      await h.tap(find.byTooltip('Back'));
      await drain(tester);
      expect(first!.isDisposed, true);
      final gate = Completer<EvidenceDocumentResult>();
      final late = await tester.runAsync(() => document('late.pdf'));
      final other = await openDocuments(tester, (_) => gate.future);
      await openUpload(other);
      await pick(tester);
      await tester.pumpWidget(const SizedBox());
      gate.complete(EvidenceDocumentResult([late!]));
      await drain(tester);
      expect(late.isDisposed, true);
      expect(await tester.runAsync(() => File(late.file.path).exists()), false);
    },
  );
  for (final size in [const Size(320, 568), const Size(393, 844)]) {
    testWidgets('Long names and document views fit $size at 1.5 text scale', (
      tester,
    ) async {
      final item = await tester.runAsync(
        () => document('${List.filled(18, 'Repair notice ').join()}.pdf'),
      );
      final h = await openDocuments(
        tester,
        (_) async => EvidenceDocumentResult([item!]),
        size: size,
        scale: 1.5,
      );
      await openUpload(h);
      await pick(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final title = tester.widget<Text>(find.text(item!.fileName));
      expect(title.overflow, TextOverflow.ellipsis);
      await h.tap(find.byKey(const ValueKey('document-upload')));
      expect(tester.takeException(), isNull);
      h.expectNext(false);
    });
  }
}
