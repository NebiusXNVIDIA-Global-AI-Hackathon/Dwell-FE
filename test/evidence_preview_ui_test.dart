import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dwell/core/theme.dart';
import 'package:dwell/features/cases/controllers/evidence_controller.dart';
import 'package:dwell/features/cases/models/evidence_model.dart';
import 'package:dwell/features/cases/widgets/creation/case_creation_bottom.dart';
import 'package:dwell/features/cases/widgets/creation/case_creation_header.dart';
import 'package:dwell/features/cases/widgets/creation/steps/evidence_step.dart';
import 'package:dwell/features/cases/widgets/creation/evidence/evidence_video_preview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'helpers/fake_evidence_video_player.dart';
import 'helpers/case_creation_test_harness.dart';
import 'case_creation_layout_test.dart' show collectLayoutProblems;

void main() {
  late Directory storage;
  late EvidenceModel video;
  late Uint8List bytes;
  setUpAll(() async {
    await loadCreationTestFonts();
    bytes = (await rootBundle.load(
      'assets/images/evidence_guide/overall_view.png',
    )).buffer.asUint8List();
  });
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('evidence-preview-test-');
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
    video = await EvidenceModel.fromVideo(
      XFile(file.path),
      duration: const Duration(seconds: 20),
      storageDirectory: storage,
    );
  });
  tearDown(() async {
    if (await storage.exists()) await storage.delete(recursive: true);
  });

  Future<void> show(
    WidgetTester tester,
    EvidenceController state, {
    Size size = const Size(393, 844),
    double scale = 1,
    VoidCallback? onAdd,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  children: [
                    CaseCreationHeader(
                      title: 'Add Evidence',
                      currentStep: 5,
                      totalSteps: 7,
                      onBack: () {},
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: EvidenceStep(
                        evidence: state,
                        onAdd: onAdd ?? () {},
                      ),
                    ),
                    const SizedBox(height: 16),
                    const CaseCreationBottom(
                      label: 'Check',
                      enabled: false,
                      onNext: null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> clear(WidgetTester tester, EvidenceController state) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    state.dispose();
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  Future<EvidenceModel> photo(WidgetTester tester) async =>
      (await tester.runAsync(
        () => EvidenceModel.fromFile(XFile.fromData(bytes, name: 'photo.png')),
      ))!;

  testWidgets(
    'Photo main preview covers; horizontal thumbnails select, delete and add',
    (tester) async {
      final state = EvidenceController();
      final first = await photo(tester);
      final second = await photo(tester);
      state.add(first);
      state.add(second);
      var adds = 0;
      await show(tester, state, onAdd: () => adds++);
      final image = tester.widget<Image>(
        find.byWidgetPredicate(
          (w) => w is Image && w.semanticLabel == 'Selected photo',
        ),
      );
      expect(image.fit, BoxFit.cover);
      final firstRect = tester.getRect(find.byKey(ValueKey(first.id)));
      final secondRect = tester.getRect(find.byKey(ValueKey(second.id)));
      final plusRect = tester.getRect(
        find.byKey(const ValueKey('evidence-add')),
      );
      expect(firstRect.top, secondRect.top);
      expect(secondRect.top, plusRect.top);
      expect(firstRect.width, firstRect.height);
      expect(plusRect.left, greaterThan(secondRect.right));
      await tester.tap(find.byKey(ValueKey(first.id)));
      await tester.pumpAndSettle();
      expect(state.selected, same(first));
      await tester.tap(find.byTooltip('Delete photo 2'));
      await tester.pumpAndSettle();
      expect(state.items, [first]);
      await tester.tap(find.byKey(const ValueKey('evidence-add')));
      expect(adds, 1);
      await tester.tap(find.byTooltip('Delete selected evidence'));
      await tester.pumpAndSettle();
      expect(state.items, isEmpty);
      expect(find.text('Damage is visible'), findsNothing);
      expect(tester.takeException(), isNull);
      await clear(tester, state);
    },
  );

  for (final mediaSize in [
    const Size(1080, 1920),
    const Size(1920, 1080),
    const Size(800, 800),
  ]) {
    testWidgets(
      'Metadata ratio stays contained with bottom controls at $mediaSize',
      (tester) async {
        final platform = FakeEvidenceVideoPlayer()
          ..size = mediaSize
          ..duration = const Duration(seconds: 20);
        final original = VideoPlayerPlatform.instance;
        VideoPlayerPlatform.instance = platform;
        addTearDown(() => VideoPlayerPlatform.instance = original);
        final state = EvidenceController()..add(video);
        await show(tester, state);
        final previewRect = tester.getRect(find.byType(EvidenceVideoPreview));
        final contentRect = tester.getRect(
          find.byKey(const ValueKey('evidence-video-content')),
        );
        expect(
          contentRect.width / contentRect.height,
          closeTo(mediaSize.width / mediaSize.height, 0.0001),
        );
        expect(contentRect.width, lessThanOrEqualTo(previewRect.width + 0.01));
        expect(
          contentRect.height,
          lessThanOrEqualTo(previewRect.height + 0.01),
        );
        if (mediaSize.width < mediaSize.height) {
          expect(contentRect.width, lessThan(previewRect.width));
        }
        final playRect = tester.getRect(find.byTooltip('Play video'));
        expect(playRect.center.dy, greaterThan(previewRect.center.dy));
        expect(find.text('00:00 / 00:20'), findsOneWidget);
        await tester.tap(find.byTooltip('Play video'));
        await tester.pump();
        expect(platform.plays, 1);
        platform.position = const Duration(seconds: 3);
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump();
        expect(find.text('00:03 / 00:20'), findsOneWidget);
        await tester.tap(find.byTooltip('Pause video'));
        await tester.pump();
        expect(platform.pauses, greaterThanOrEqualTo(1));
        await tester.tap(find.byTooltip('Delete selected evidence'));
        await tester.pumpAndSettle();
        expect(state.items, isEmpty);
        expect(tester.takeException(), isNull);
        await clear(tester, state);
      },
    );
  }

  for (final size in [const Size(320, 568), const Size(393, 844)]) {
    testWidgets(
      'Many attachments scroll horizontally; Check stays fixed at $size',
      (tester) async {
        final platform = FakeEvidenceVideoPlayer()
          ..size = const Size(1080, 1920);
        final original = VideoPlayerPlatform.instance;
        VideoPlayerPlatform.instance = platform;
        addTearDown(() => VideoPlayerPlatform.instance = original);
        final state = EvidenceController();
        for (var i = 0; i < 8; i++) {
          state.add(await photo(tester));
        }
        state.add(video);
        await show(tester, state, size: size, scale: 1.5);
        final check = find.widgetWithText(FilledButton, 'Check');
        final checkRect = tester.getRect(check);
        expect(tester.widget<FilledButton>(check).onPressed, isNull);
        final problems = <String>[];
        collectLayoutProblems(
          tester,
          find.byType(Scaffold),
          'mixed evidence',
          problems,
        );
        expect(problems, isEmpty);
        final list = find.byKey(const ValueKey('evidence-thumbnails'));
        await tester.ensureVisible(list);
        await tester.pumpAndSettle();
        await tester.drag(list, const Offset(-900, 0));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('evidence-add')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.getRect(check), checkRect);
        expect(state.items.length, 9);
        expect(tester.takeException(), isNull);
        await clear(tester, state);
      },
    );
  }
}
