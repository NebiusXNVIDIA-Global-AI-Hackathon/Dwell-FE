import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dwell/features/cases/models/evidence_model.dart';
import 'package:dwell/features/cases/services/evidence_documents.dart';
import 'package:dwell/features/cases/services/evidence_document_format.dart';
import 'package:dwell/features/cases/controllers/evidence_controller.dart';

import 'helpers/evidence_document_fixtures.dart';

base class TestDocumentFile extends PlatformFile {
  TestDocumentFile(
    this.name,
    this.data, {
    this.reported,
    this.unknown = false,
    this.error,
  });
  @override
  final String name;
  final Uint8List data;
  final int? reported;
  final bool unknown;
  final Object? error;
  int reads = 0;
  @override
  Uri get uri => Uri.parse('test:$name');
  @override
  XFile get xFile => XFile.fromData(data, name: name);
  @override
  int? lengthSync() => unknown ? null : reported ?? data.length;
  @override
  Future<int?> length() async => lengthSync();
  @override
  Future<Uint8List> readAsBytes() async {
    reads++;
    if (error != null) throw error!;
    return data;
  }

  @override
  Stream<Uint8List> readAsByteStream() async* {
    reads++;
    if (error != null) throw error!;
    yield data;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('document-test-');
  });
  tearDown(() async {
    await storage.delete(recursive: true);
  });
  Future<EvidenceModel> save(Uint8List data, String name) =>
      EvidenceModel.fromDocument(data, name: name, storageDirectory: storage);
  test('Dropped files reuse picker validation and release, without opening a chooser', () async {
    final released = <PlatformFile>[];
    final files = [
      TestDocumentFile('drop.pdf', pdfDocument()),
      TestDocumentFile('wrong.docx', pdfDocument()),
    ];
    final picker = DeviceEvidenceDocuments(
      pickFiles: () async => throw StateError('Must not open picker'),
      save: save,
      release: (file) async {
        released.add(file);
      },
    );
    final result = await picker.pickDocuments({}, files: files);
    expect(result.documents.length, 1);
    expect(result.failures.length, 1);
    expect(released, files);
    await result.documents.single.dispose();
  });
  test(
    'PDF, DOC, DOCX contents pass and mislabeled/truncated containers fail',
    () {
      expect(
        validateEvidenceDocument(pdfDocument(), 'notice.PDF'),
        'application/pdf',
      );
      expect(
        validateEvidenceDocument(docDocument(), 'lease.doc'),
        'application/msword',
      );
      expect(
        validateEvidenceDocument(docxDocument(), 'lease.docx'),
        contains('wordprocessingml.document'),
      );
      for (final entry in [
        (pdfDocument(), 'notice.doc'),
        (docxDocument(), 'notice.pdf'),
        (docxDocument(word: false), 'spreadsheet.docx'),
        (docDocument(stream: 'Workbook'), 'spreadsheet.doc'),
        (Uint8List.fromList([0x50, 0x4b, 3, 4]), 'corrupt.docx'),
        (Uint8List.fromList([0xd0, 0xcf, 0x11, 0xe0]), 'corrupt.doc'),
        (Uint8List.fromList('%PDF-1.7'.codeUnits), 'unfinished.pdf'),
        (pdfDocument(), 'notice.txt'),
      ]) {
        expect(
          () => validateEvidenceDocument(entry.$1, entry.$2),
          throwsFormatException,
        );
      }
    },
  );
  testWidgets(
    'Reference-supported PNG validates pixels, caches a small preview and rejects forged image headers',
    (tester) async {
      final bytes = (await rootBundle.load(
        'assets/images/evidence_guide/overall_view.png',
      )).buffer.asUint8List();
      final image = await tester.runAsync(() => save(bytes, 'Evidence.PNG'));
      expect(image!.mimeType, 'image/png');
      expect(image.documentPreviewBytes, isNotEmpty);
      expect(image.documentSize, bytes.length);
      expect(await tester.runAsync(() => image.file.readAsBytes()), bytes);
      await tester.runAsync(image.dispose);
      expect(image.documentPreviewBytes, isNull);
      final forged = Uint8List.fromList([
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
        0,
        0,
        0,
        0,
      ]);
      await tester.runAsync(() async {
        await expectLater(save(forged, 'fake.png'), throwsA(anything));
      });
      expect(
        () => validateEvidenceDocument(bytes, 'renamed.jpg'),
        throwsFormatException,
      );
    },
  );
  test(
    'Metadata preserves safe original name; native cache deletion keeps source',
    () async {
      final source = File('${storage.path}/source.pdf');
      await source.writeAsBytes(pdfDocument());
      final document = await save(
        await source.readAsBytes(),
        '../Notice\u202e.pdf',
      );
      expect(document.type, EvidenceType.document);
      expect(document.fileName, 'Notice.pdf');
      expect(document.documentSize, 96);
      expect(document.bytes, isEmpty);
      expect(await document.file.readAsBytes(), pdfDocument());
      expect(document.documentFingerprint, isNotEmpty);
      final controller = EvidenceController()..add(document);
      expect(controller.selected, same(document));
      controller.remove(document.id);
      await document.dispose();
      expect(await File(document.file.path).exists(), false);
      expect(await source.exists(), true);
      expect(controller.items, isEmpty);
      controller.dispose();
    },
  );
  test('Multi-select partially succeeds, reads once and releases every picked file', () async {
    final files = [
      TestDocumentFile('notice.pdf', pdfDocument()),
      TestDocumentFile('lease.doc', docDocument()),
      TestDocumentFile('letter.docx', docxDocument()),
      TestDocumentFile('wrong.pdf', docxDocument()),
      TestDocumentFile('empty.pdf', Uint8List(0)),
      TestDocumentFile(
        'large.pdf',
        Uint8List(0),
        reported: evidenceDocumentLimit + 1,
      ),
      TestDocumentFile('unsupported.txt', pdfDocument()),
      TestDocumentFile(
        'unreadable.pdf',
        pdfDocument(),
        error: StateError('read failed'),
      ),
    ];
    final released = <PlatformFile>[];
    final picker = DeviceEvidenceDocuments(
      pickFiles: () async => files,
      save: save,
      release: (f) async {
        released.add(f);
      },
    );
    final result = await picker.pickDocuments({});
    expect(result.documents.length, 3);
    expect(result.failures.length, 5);
    expect(released, files);
    expect(files[0].reads, 1);
    expect(files[5].reads, 0);
    expect(files[6].reads, 0);
    for (final document in result.documents) {
      await document.dispose();
    }
  });
  test(
    '10 MB accepted; oversize unknown stream and inconsistent length rejected',
    () async {
      final files = [
        TestDocumentFile('limit.pdf', pdfDocument(size: evidenceDocumentLimit)),
        TestDocumentFile(
          'over.pdf',
          pdfDocument(size: evidenceDocumentLimit + 1),
          unknown: true,
        ),
        TestDocumentFile('partial.pdf', pdfDocument(), reported: 200),
      ];
      final picker = DeviceEvidenceDocuments(
        pickFiles: () async => files,
        save: save,
        release: (_) async {},
      );
      final result = await picker.pickDocuments({});
      expect(result.documents.single.documentSize, evidenceDocumentLimit);
      expect(result.failures.length, 2);
      await result.documents.single.dispose();
    },
  );
  test('Content duplicates within and across selections leave no extra owned cache', () async {
    final picker = DeviceEvidenceDocuments(
      pickFiles: () async => [
        TestDocumentFile('one.pdf', pdfDocument()),
        TestDocumentFile('renamed.pdf', pdfDocument()),
      ],
      save: save,
      release: (_) async {},
    );
    final first = await picker.pickDocuments({});
    expect(first.documents.length, 1);
    expect(first.failures.single, contains('already attached'));
    final second = await picker.pickDocuments({
      first.documents.single.documentFingerprint!,
    });
    expect(second.documents, isEmpty);
    expect(second.failures.length, 2);
    expect((await storage.list().toList()).length, 1);
    await first.documents.single.dispose();
    expect(await storage.list().isEmpty, true);
  });
  test('Cancel and concurrent touches do not open another picker; errors release lock', () async {
    final gate = Completer<List<PlatformFile>>();
    var calls = 0;
    final picker = DeviceEvidenceDocuments(
      pickFiles: () {
        calls++;
        return gate.future;
      },
      save: save,
    );
    final first = picker.pickDocuments({});
    expect((await picker.pickDocuments({})).documents, isEmpty);
    expect(calls, 1);
    gate.complete([]);
    expect((await first).failures, isEmpty);
    final fails = DeviceEvidenceDocuments(
      pickFiles: () async => throw PlatformException(code: 'permission_denied'),
    );
    await expectLater(
      fails.pickDocuments({}),
      throwsA(isA<PlatformException>()),
    );
    await expectLater(
      fails.pickDocuments({}),
      throwsA(isA<PlatformException>()),
    );
    expect(
      evidenceDocumentPickerError(PlatformException(code: 'permission_denied')),
      contains('denied'),
    );
  });
}
