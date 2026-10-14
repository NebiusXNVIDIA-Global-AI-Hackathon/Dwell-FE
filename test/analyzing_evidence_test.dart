import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:dwell/core/theme.dart';
import 'package:dwell/features/cases/controllers/evidence_analysis_controller.dart';
import 'package:dwell/features/cases/models/case_draft.dart';
import 'package:dwell/features/cases/models/evidence_analysis_input.dart';
import 'package:dwell/features/cases/models/evidence_model.dart';
import 'package:dwell/features/cases/pages/analyzing_evidence_page.dart';
import 'package:dwell/features/cases/pages/case_created_page.dart';
import 'package:dwell/features/cases/widgets/creation/evidence_analysis_preview.dart';
import 'package:dwell/features/cases/widgets/creation/evidence/evidence_audio_preview.dart';
import 'package:dwell/features/cases/widgets/creation/evidence/evidence_video_preview.dart';
import 'package:dwell/features/cases/services/evidence_video_thumbnail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'description_step_test.dart' show openDescription;
import 'evidence_check_test.dart' show checkPhoto;
import 'helpers/case_creation_test_harness.dart';
import 'helpers/fake_evidence_video_player.dart';

void main() {
  setUpAll(() async {
    await loadCreationTestFonts();
    await (FontLoader('packages/lucide_icons_flutter/Lucide')..addFont(
          rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
        ))
        .load();
  });

  if (const bool.fromEnvironment('DWELL_ANALYSIS_PREVIEW')) {
    testWidgets('Analysis single and multiple design previews', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      final photos = [
        await checkPhoto(tester),
        await checkPhoto(tester),
        await checkPhoto(tester),
      ];
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        for (final photo in photos) {
          await photo.dispose();
        }
      });
      for (final count in [1, 3]) {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: buildTheme(Brightness.light),
              home: AnalyzingEvidencePage(
                key: ValueKey(count),
                input: EvidenceAnalysisInput(
                  CaseDraftView(CaseDraft()),
                  photos.take(count).toList(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 2800));
        // Native image decodes run outside the widget test's fake clock.
        for (var attempt = 0; attempt < 10; attempt++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump(const Duration(milliseconds: 10));
        }
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary).first,
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          final directory = Directory(
            '${Directory.systemTemp.path}/dwell-diagnostics',
          );
          await directory.create(recursive: true);
          await File('${directory.path}/analysis-$count.png')
              .writeAsBytes(data!.buffer.asUint8List());
        });
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets(
    'Leaving analysis early cancels progress and never fires completion',
    (tester) async {
      final runner = MockEvidenceAnalysisController(
        interval: const Duration(milliseconds: 100),
      );
      final photo = await checkPhoto(tester);
      addTearDown(photo.dispose);
      var completed = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            evidenceAnalysisControllerFactoryProvider.overrideWithValue(
              () => runner,
            ),
          ],
          child: MaterialApp(
            home: AnalyzingEvidencePage(
              input: EvidenceAnalysisInput(CaseDraftView(CaseDraft()), [photo]),
              onMockCompleted: () => completed++,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(runner.completedCount, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
      expect(runner.completedCount, 1);
      expect(completed, 0);
      expect(photo.isDisposed, false);
      expect(tester.takeException(), isNull);
    },
  );
  for (final skip in [false, true]) {
    testWidgets(
      '${skip ? "Skip" : "Submit"} routes to analysis with draft/evidence and Back retains ownership',
      (tester) async {
        final h = await openDescription(tester, useAnalysisRoute: true);
        await h.enter(' Original description ');
        final target = skip
            ? find.byKey(const ValueKey('description-skip'))
            : h.nextButton;
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        final page = tester.widget<AnalyzingEvidencePage>(
          find.byType(AnalyzingEvidencePage),
        );
        expect(
          GoRouterState.of(tester.element(find.byType(AnalyzingEvidencePage)))
              .uri
              .path,
          '/cases/new/analyzing',
        );
        expect(
          page.input.draft.description,
          skip ? '' : ' Original description ',
        );
        expect(page.input.draft.issueType, 'Plumbing');
        expect(page.input.draft.location, 'Kitchen');
        expect(page.input.draft.affectedArea, 'Ceiling');
        final photo = page.input.evidence.single;
        expect(photo.isDisposed, false);
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.text('steps 6 of 6'), findsNothing);
        expect(
          find.byKey(ValueKey('analysis-primary-${photo.id}')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('analysis-thumbnails')), findsNothing);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        h.expectStep(6);
        expect(h.input, ' Original description ');
        expect(photo.isDisposed, false);
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
        final created = tester.widget<CaseCreatedPage>(
          find.byType(CaseCreatedPage),
        );
        expect(created.result.isDemo, true);
        expect(created.result.input.evidence.single, same(photo));
        expect(
          created.result.input.draft.description,
          skip ? '' : ' Original description ',
        );
        expect(photo.isDisposed, false);
        expect(find.byType(AnalyzingEvidencePage), findsNothing);
        h.router.go('/cases');
        await tester.pumpAndSettle();
        expect(photo.isDisposed, true);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Deep link without in-memory attachments safely returns to creation',
    (tester) async {
      final h = await CreationHarness.start(tester, direct: true);
      h.router.go('/cases/new/analyzing');
      await tester.pumpAndSettle();
      expect(find.byType(AnalyzingEvidencePage), findsNothing);
      h.expectStep(1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Mixed attachments preserve order; native video/audio previews release readers, not files',
    (tester) async {
      final platform = FakeEvidenceVideoPlayer();
      final original = VideoPlayerPlatform.instance;
      VideoPlayerPlatform.instance = platform;
      addTearDown(() => VideoPlayerPlatform.instance = original);
      final photo = await checkPhoto(tester);
      final storage = await tester.runAsync(
        () => Directory.systemTemp.createTemp('analysis-test-'),
      );
      final media = await tester.runAsync(() async {
        final raw = await File('${storage!.path}/raw.mp4').writeAsBytes([
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
      final items = [photo, ...media!];
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() async {
          for (final item in items) {
            await item.dispose();
          }
          await storage!.delete(recursive: true);
        });
      });
      Future<void> show(List<EvidenceModel> values) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              evidenceThumbnailExtractorProvider.overrideWithValue(
                (_, _) async => photo.bytes,
              ),
            ],
            child: MaterialApp(
              theme: buildTheme(Brightness.light),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: EvidenceAnalysisPreview(evidence: values),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show(items);
      expect(
        find.byKey(ValueKey('analysis-primary-${photo.id}')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('analysis-thumbnail-${media[0].id}')),
        findsOneWidget,
      );
      expect(find.byType(EvidenceAudioWave), findsOneWidget);
      await show([media[0]]);
      expect(find.byType(EvidenceVideoPreview), findsOneWidget);
      expect(find.byKey(const ValueKey('evidence-video-play')), findsOneWidget);
      await show([media[1]]);
      expect(find.byType(EvidenceAudioPreview), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(items.every((item) => !item.isDisposed), true);
      for (
        var attempt = 0;
        attempt < 50 && platform.completedDisposals < platform.creates;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 2)),
        );
        await tester.pump();
      }
      expect(media.every((item) => item.activeMediaReaders == 0), true);
      expect(
        await tester.runAsync(() => File(media[0].file.path).exists()),
        true,
      );
      expect(
        await tester.runAsync(() => File(media[1].file.path).exists()),
        true,
      );
      expect(platform.creates, platform.completedDisposals);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(1280, 800),
  ]) {
    testWidgets(
      'Analysis fits $size with 2x text and notifies completion once',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final photo = await checkPhoto(tester);
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox());
          await photo.dispose();
        });
        var completed = 0;
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: buildTheme(Brightness.light),
              home: AnalyzingEvidencePage(
                input: EvidenceAnalysisInput(CaseDraftView(CaseDraft()), [
                  photo,
                ]),
                onMockCompleted: () => completed++,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.text('This usually takes a few seconds ...'),
        );
        await tester.pumpAndSettle();
        expect(completed, 1);
        await tester.pump(const Duration(seconds: 5));
        expect(completed, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
