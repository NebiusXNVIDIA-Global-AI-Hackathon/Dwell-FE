import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:dwell/core/theme.dart';
import 'package:dwell/features/cases/data/mock_cases.dart';
import 'package:dwell/features/cases/models/case_creation_result.dart';
import 'package:dwell/features/cases/models/case_draft.dart';
import 'package:dwell/features/cases/models/case_model.dart';
import 'package:dwell/features/cases/models/evidence_analysis_input.dart';
import 'package:dwell/features/cases/models/evidence_model.dart';
import 'package:dwell/features/cases/pages/case_created_page.dart';
import 'package:dwell/features/cases/widgets/creation/evidence/evidence_audio_preview.dart';
import 'package:dwell/features/cases/widgets/creation/evidence/evidence_video_thumbnail.dart';
import 'package:dwell/features/cases/services/evidence_video_thumbnail.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'description_step_test.dart' show openDescription;
import 'evidence_check_test.dart' show checkPhoto;
import 'helpers/case_creation_test_harness.dart';

void main() {
  setUpAll(() async {
    await loadCreationTestFonts();
    await (FontLoader('packages/lucide_icons_flutter/Lucide')..addFont(
          rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
        ))
        .load();
  });
  test('Demo never records saved/AI/tamper flags or guesses a severity', () {
    final draft = CaseDraft()
      ..issueType = 'Plumbing'
      ..specificIssue = 'Other'
      ..otherIssue = ' Water leak '
      ..location = 'Bathroom'
      ..affectedArea = 'Ceiling'
      ..description = 'Retained';
    final input = EvidenceAnalysisInput(CaseDraftView(draft), []);
    final demo = CaseCreationResult.demo(
      input,
      previewedAt: DateTime(2026, 9, 28, 18, 42),
    );
    expect(demo.id, startsWith('DEMO-'));
    expect(demo.title, 'Water leak');
    expect(demo.locationSummary, 'Bathroom · Ceiling');
    expect(demo.input.draft.description, 'Retained');
    expect(demo.severity, isNull);
    expect(
      demo.originalFileSaved ||
          demo.analysisAttached ||
          demo.tamperProtectionConfirmed,
      false,
    );
    final actual = CaseCreationResult.confirmed(
      input,
      mockCases.first,
      originalFileSaved: true,
      analysisAttached: false,
      tamperProtectionConfirmed: false,
    );
    expect(actual.isDemo, false);
    expect(actual.id, mockCases.first.id);
    expect(actual.severity, CaseSeverity.high);
    expect(actual.analysisAttached, false);
  });

  testWidgets(
    'Mock success -> Reports clears flow, shows demo notification and preserves list',
    (tester) async {
      final count = mockCases.length;
      final h = await openDescription(tester, useAnalysisRoute: true);
      await h.enter('Leak description');
      await tester.ensureVisible(h.nextButton);
      await tester.tap(h.nextButton);
      await tester.pumpAndSettle();
      final page = tester.widget<CaseCreatedPage>(find.byType(CaseCreatedPage));
      final photo = page.result.input.evidence.single;
      expect(find.text('Original file saved'), findsOneWidget);
      expect(find.text('AI Analysis attached'), findsOneWidget);
      expect(find.text('Protected from tampering'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      final view = find.widgetWithText(FilledButton, 'View Analysis');
      expect(tester.widget<FilledButton>(view).onPressed, isNull);
      expect(photo.isDisposed, false);
      final back = find.widgetWithText(FilledButton, 'Back to main');
      await tester.ensureVisible(back);
      final action = tester.widget<FilledButton>(back).onPressed!;
      action();
      action();
      await tester.pumpAndSettle();
      expect(h.router.routeInformationProvider.value.uri.path, '/cases');
      expect(h.router.canPop(), false);
      expect(find.text('Case created successfully'), findsOneWidget);
      expect(find.text('Demo only · No case was saved'), findsOneWidget);
      expect(photo.isDisposed, true);
      expect(mockCases.length, count);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(390, 844),
    const Size(320, 568),
    const Size(1280, 800),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Created layout at $size/$scale respects verified flags and optional analysis callback',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final photo = await checkPhoto(tester);
          addTearDown(() async {
            await tester.pumpWidget(const SizedBox());
            await photo.dispose();
          });
          final input = EvidenceAnalysisInput(CaseDraftView(CaseDraft()), [
            photo,
          ]);
          final result = CaseCreationResult.confirmed(
            input,
            mockCases.first,
            originalFileSaved: true,
            analysisAttached: true,
            tamperProtectionConfirmed: false,
          );
          var opened = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: buildTheme(Brightness.light),
              home: CaseCreatedPage(
                result: result,
                onViewAnalysis: () => opened++,
              ),
            ),
          );
          expect(find.byIcon(LucideIcons.check), findsNWidgets(2));
          final view = find.widgetWithText(FilledButton, 'View Analysis');
          await tester.ensureVisible(view);
          await tester.tap(view);
          await tester.pumpAndSettle();
          expect(opened, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('Video and audio summary previews use the actual owned media', (
    tester,
  ) async {
    final photo = await checkPhoto(tester);
    final storage = await tester.runAsync(
      () => Directory.systemTemp.createTemp('created-test-'),
    );
    final media = await tester.runAsync(() async {
      final raw = await File('${storage!.path}/source.mp4').writeAsBytes([
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
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
      ]);
      return [
        await EvidenceModel.fromVideo(
          XFile(raw.path),
          duration: const Duration(seconds: 6),
          storageDirectory: storage,
        ),
        await EvidenceModel.fromAudio(
          XFile(raw.path),
          duration: const Duration(seconds: 6),
          storageDirectory: storage,
        ),
      ];
    });
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await photo.dispose();
        for (final item in media!) {
          await item.dispose();
        }
        await storage!.delete(recursive: true);
      });
    });
    for (final item in media!) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            evidenceThumbnailExtractorProvider.overrideWithValue(
              (_, _) async => photo.bytes,
            ),
          ],
          child: MaterialApp(
            home: CaseCreatedPage(
              result: CaseCreationResult.demo(
                EvidenceAnalysisInput(CaseDraftView(CaseDraft()), [item]),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        item.type == EvidenceType.video
            ? find.byType(EvidenceVideoThumbnail)
            : find.byType(EvidenceAudioWave),
        findsOneWidget,
      );
      expect(item.isDisposed, false);
    }
    expect(tester.takeException(), isNull);
  });

  if (const bool.fromEnvironment('DWELL_CREATED_PREVIEW')) {
    testWidgets('Created screen design preview', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      final photo = await checkPhoto(tester);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await photo.dispose();
      });
      final draft = CaseDraft()
        ..specificIssue = 'Other'
        ..otherIssue = 'Water leak'
        ..location = 'Bathroom'
        ..affectedArea = 'Ceiling';
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          home: CaseCreatedPage(
            result: CaseCreationResult.demo(
              EvidenceAnalysisInput(CaseDraftView(draft), [photo]),
              previewedAt: DateTime(2026, 9, 28, 18, 42),
            ),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first,
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        await File(
          '${Directory.systemTemp.path}/dwell-diagnostics/case-created.png',
        ).writeAsBytes(data!.buffer.asUint8List());
      });
      expect(tester.takeException(), isNull);
    });
  }
}
