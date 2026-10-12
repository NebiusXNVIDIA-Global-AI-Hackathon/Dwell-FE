import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:dwell/features/cases/models/evidence_model.dart';
import 'package:dwell/features/cases/services/evidence_media_platform.dart';

import 'evidence_document_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Browser documents keep independent Blob ownership and revoke on delete',
    () async {
      for (final fixture in [
        (pdfDocument(), 'notice.pdf', 'application/pdf'),
        (docDocument(), 'lease.doc', 'application/msword'),
        (
          docxDocument(),
          'letter.docx',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        ),
      ]) {
        final picked = createEvidenceBlob(fixture.$1, fixture.$3, fixture.$2);
        final document = await EvidenceModel.fromDocument(
          await picked.readAsBytes(),
          name: picked.name,
        );
        expect(document.file.path.startsWith('blob:'), true);
        expect(document.file.path, isNot(picked.path));
        await releasePickedDocument(Uri.parse(picked.path));
        expect(await document.file.readAsBytes(), fixture.$1);
        expect(document.mimeType, fixture.$3);
        expect(document.fileName, fixture.$2);
        final uri = document.file.path;
        await document.dispose();
        // A fresh XFile has no cached Blob, so reading tests URL revocation.
        await expectLater(XFile(uri).readAsBytes(), throwsA(anything));
      }
    },
  );
}
