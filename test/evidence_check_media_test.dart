import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dwell/features/cases/models/evidence_model.dart';
import 'package:dwell/features/cases/widgets/creation/steps/evidence_step.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'helpers/case_creation_test_harness.dart';
import 'helpers/fake_evidence_video_player.dart';
import 'evidence_check_test.dart' show checkPage;

void main() {
  setUpAll(loadCreationTestFonts);
  for (final type in [EvidenceType.audio, EvidenceType.video]) {
    testWidgets('Mock checks keep $type player and playback unchanged', (
      tester,
    ) async {
      final previous = VideoPlayerPlatform.instance;
      final player = FakeEvidenceVideoPlayer();
      VideoPlayerPlatform.instance = player;
      addTearDown(() {
        VideoPlayerPlatform.instance = previous;
      });
      final storage = await tester.runAsync(
        () => Directory.systemTemp.createTemp('mock-check-media-'),
      );
      final file = await tester.runAsync(
        () async => XFile(
          (await File('${storage!.path}/source.mp4').writeAsBytes([
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
          ])).path,
        ),
      );
      final media = await tester.runAsync(
        () => type == EvidenceType.audio
            ? EvidenceModel.fromAudio(
                file!,
                duration: const Duration(seconds: 6),
                storageDirectory: storage,
              )
            : EvidenceModel.fromVideo(
                file!,
                duration: const Duration(seconds: 6),
                storageDirectory: storage,
              ),
      );
      final h = await checkPage(tester);
      final step = tester.widget<EvidenceStep>(find.byType(EvidenceStep));
      step.evidence!.add(media!);
      await tester.pumpAndSettle();
      await h.tap(find.byKey(ValueKey('evidence-${type.name}-play')));
      final creates = player.creates,
          pauses = player.pauses,
          plays = player.plays;
      await tester.tap(h.nextButton);
      await tester.pump();
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 700));
        expect(player.creates, creates);
        expect(player.pauses, pauses);
        expect(player.plays, plays);
      }
      expect(media.isDisposed, false);
      expect(media.duration, const Duration(seconds: 6));
      await tester.pumpWidget(const SizedBox());
      for (var i = 0; i < 8; i++) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
      }
      await tester.runAsync(() async {
        await media.dispose();
        await storage!.delete(recursive: true);
      });
      expect(tester.takeException(), isNull);
    });
  }
}
