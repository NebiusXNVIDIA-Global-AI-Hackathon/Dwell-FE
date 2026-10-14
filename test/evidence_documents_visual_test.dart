import 'dart:io';
import 'dart:ui' as ui;

import 'package:dwell/core/theme.dart';
import 'package:dwell/features/cases/models/evidence_model.dart';
import 'package:dwell/features/cases/pages/evidence/evidence_documents_page.dart';
import 'package:dwell/features/cases/services/evidence_documents.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/case_creation_test_harness.dart';
import 'helpers/evidence_document_fixtures.dart';

void main() {
  setUpAll(() async {
    await loadCreationTestFonts();
    for (final font in [
      ('Lucide', 'assets/lucide.ttf'),
      ('Lucide300', 'assets/build_font/LucideVariable-w300.ttf'),
    ]) {
      final loader = FontLoader('packages/lucide_icons_flutter/${font.$1}')
        ..addFont(
          rootBundle.load(
              'packages/lucide_icons_flutter/${font.$2}',
          ),
        );
      await loader.load();
    }
  });
  testWidgets(
    'Reference empty and selected states render with pinned Upload and safe insets',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      final storage = await tester.runAsync(
        () => Directory.systemTemp.createTemp('document-visual-'),
      );
      final file = await tester.runAsync(
        () => EvidenceModel.fromDocument(
          pdfDocument(size: 8 * 1024 * 1024),
          name: 'Repair Notice.pdf',
          storageDirectory: storage,
        ),
      );
      final capture = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            evidenceDocumentPickerProvider.overrideWithValue(
              (_) async => EvidenceDocumentResult([file!]),
            ),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: RepaintBoundary(
              key: capture,
              child: const EvidenceDocumentsPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> screenshot(String name) async {
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          final directory = Directory('build/document-previews');
          await directory.create(recursive: true);
          await File('${directory.path}/$name.png')
              .writeAsBytes(data!.buffer.asUint8List());
        });
      }

      await screenshot('empty');
      final buttonPosition = tester.getRect(
        find.byKey(const ValueKey('document-upload')),
      );
      expect(buttonPosition.bottom, 810);
      await tester.tap(find.byKey(const ValueKey('document-choose-files')));
      await tester.pumpAndSettle();
      expect(find.text('Selected File (1)'), findsOneWidget);
      expect(find.text('PDF · 8MB'), findsOneWidget);
      expect(
        tester.getRect(find.byKey(const ValueKey('document-upload'))),
        buttonPosition,
      );
      expect(tester.takeException(), isNull);
      await screenshot('selected');
      await tester.pumpWidget(const SizedBox());
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      await tester.runAsync(() async {
        await file!.dispose();
        await storage!.delete(recursive: true);
      });
    },
  );
}
