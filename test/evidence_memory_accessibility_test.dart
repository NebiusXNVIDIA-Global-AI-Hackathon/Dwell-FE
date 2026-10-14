import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:dwell/features/cases/controllers/evidence_controller.dart';
import 'package:dwell/features/cases/controllers/mock_evidence_check_controller.dart';
import 'package:dwell/features/cases/models/evidence_model.dart';
import 'package:dwell/features/cases/widgets/creation/steps/evidence_step.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<EvidenceModel> photo(WidgetTester tester) async =>
      (await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawColor(Colors.blue, BlendMode.src);
        final picture = recorder.endRecording();
        final image = await picture.toImage(3200, 2400);
        picture.dispose();
        try {
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!.buffer.asUint8List();
          return await EvidenceModel.fromFile(
            XFile.fromData(bytes, name: 'large.png'),
          );
        } finally {
          image.dispose();
        }
      }))!;

  Future<void> show(
    WidgetTester tester,
    EvidenceController state, {
    MockEvidenceCheckController? mock,
    double dpr = 2,
  }) async {
    tester.view.devicePixelRatio = dpr;
    tester.view.physicalSize = Size(320 * dpr, 700 * dpr);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EvidenceStep(evidence: state, mockCheck: mock, onAdd: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test(
    'Release/profile require an explicit demo flag; debug keeps the demo',
    () {
      expect(
        const EvidenceDemoPolicy(debug: false, demoFlag: false).enabled,
        false,
      );
      expect(
        const EvidenceDemoPolicy(debug: false, demoFlag: true).enabled,
        true,
      );
      expect(
        const EvidenceDemoPolicy(debug: true, demoFlag: false).enabled,
        true,
      );
      expect(mockEvidenceCheckPolicy.enabled, true);
    },
  );

  testWidgets('High resolution photo uses separate DPR-aware cover decodes', (
    tester,
  ) async {
    final item = await photo(tester);
    final state = EvidenceController()..add(item);
    expect(item.photoWidth, 3200);
    expect(item.photoHeight, 2400);
    expect(item.bytes.length, lessThan(3200 * 2400 * 4));
    await show(tester, state);
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    final main = images.singleWhere(
      (image) => image.semanticLabel == 'Selected photo',
    );
    final thumb = images.singleWhere((image) => image.excludeFromSemantics);
    final mainProvider = main.image as ResizeImage;
    final thumbProvider = thumb.image as ResizeImage;
    expect(mainProvider.width, 640);
    expect(mainProvider.height, isNull); // Decoder preserves source ratio.
    expect(thumbProvider.width, 192); // 144 high at 4:3 for square cover.
    expect(main.fit, BoxFit.cover);
    expect(thumb.fit, BoxFit.cover);
    final stream = thumb.image.resolve(ImageConfiguration.empty);
    ImageInfo? decoded;
    final listener = ImageStreamListener((info, _) => decoded = info);
    stream.addListener(listener);
    for (var i = 0; i < 500 && decoded == null; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 2)),
      );
      await tester.pump();
    }
    expect(decoded, isNotNull, reason: 'Photo decode did not finish');
    expect(decoded!.image.width / decoded!.image.height, closeTo(4 / 3, 0.01));
    stream.removeListener(listener);
    decoded?.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(item.dispose);
    expect(item.bytes, isEmpty);
    expect(
      await mainProvider.obtainCacheStatus(
        configuration: ImageConfiguration.empty,
      ),
      predicate<dynamic>(
        (status) => !status.pending && !status.live && !status.keepAlive,
      ),
    );
    expect(
      await thumbProvider.obtainCacheStatus(
        configuration: ImageConfiguration.empty,
      ),
      predicate<dynamic>(
        (status) => !status.pending && !status.live && !status.keepAlive,
      ),
    );
    state.dispose();
  });

  testWidgets(
    'Delete reserves 48 pixels and never selects the removed thumbnail',
    (tester) async {
      final first = await photo(tester), second = await photo(tester);
      final state = EvidenceController()
        ..add(first)
        ..add(second);
      var selections = 0;
      state.addListener(() {
        if (state.selected == first) selections++;
      });
      final semantics = tester.ensureSemantics();
      await show(tester, state, dpr: 1);
      final delete = find.byTooltip('Delete photo 1');
      expect(tester.getSize(delete), const Size(48, 48));
      expect(
        tester.getSemantics(delete),
        matchesSemantics(
          label: 'Delete photo 1',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      final tile = tester.getRect(find.byKey(ValueKey(first.id)));
      // Expanded target outside the original 28px corner.
      await tester.tapAt(tile.topRight + const Offset(-42, 42));
      await tester.pumpAndSettle();
      expect(state.items, [second]);
      expect(state.selected, second);
      expect(selections, 0);
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    },
  );

  testWidgets('Thumbnail selection and delete support keyboard activation', (
    tester,
  ) async {
    final first = await photo(tester), second = await photo(tester);
    final state = EvidenceController()
      ..add(first)
      ..add(second);
    await show(tester, state, dpr: 1);
    final select = tester.widget<InkWell>(find.byKey(ValueKey(first.id)));
    select.onTap!();
    await tester.pumpAndSettle();
    expect(state.selected, first);
    final button = find.byTooltip('Delete photo 2');
    final focus = Focus.of(
      tester.element(find.descendant(of: button, matching: find.byType(Icon))),
    );
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(state.items, [first]);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets(
    'Empty evidence has no notice; service builds explain disabled Check',
    (tester) async {
      final state = EvidenceController();
      final mock = MockEvidenceCheckController(state, demoEnabled: false);
      await show(tester, state);
      expect(find.byKey(const ValueKey('evidence-check-notice')), findsNothing);
      state.add(await photo(tester));
      await show(tester, state, mock: mock);
      expect(
        find.text('AI analysis not connected · Check unavailable'),
        findsOneWidget,
      );
      expect(mock.buttonEnabled, false);
      await tester.pumpWidget(const SizedBox());
      mock.dispose();
      state.dispose();
    },
  );

  testWidgets(
    'Demo notice accompanies animation and changes reset presentation only',
    (tester) async {
      final state = EvidenceController()..add(await photo(tester));
      final mock = MockEvidenceCheckController(state, demoEnabled: true);
      await show(tester, state, mock: mock);
      expect(
        find.text('Demo preview · AI analysis not connected'),
        findsOneWidget,
      );
      final original = state.selected!.bytes;
      mock.start();
      await tester.pump(mockEvidenceCheckInterval);
      expect(mock.completedCount, 1);
      expect(state.selected!.bytes, same(original));
      state.add(await photo(tester));
      await tester.pump();
      expect(mock.completedCount, 0);
      expect(mock.status, MockEvidenceCheckStatus.idle);
      await tester.pumpWidget(const SizedBox());
      mock.dispose();
      state.dispose();
    },
  );
}
