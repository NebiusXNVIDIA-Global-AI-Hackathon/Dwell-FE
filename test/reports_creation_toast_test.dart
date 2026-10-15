import 'dart:io';
import 'dart:ui' as ui;

import 'package:dwell/core/theme.dart';
import 'package:dwell/core/widgets/bottom_nav_bar.dart';
import 'package:dwell/features/cases/data/mock_cases.dart';
import 'package:dwell/features/cases/models/case_creation_result.dart';
import 'package:dwell/features/cases/models/case_draft.dart';
import 'package:dwell/features/cases/models/evidence_analysis_input.dart';
import 'package:dwell/features/cases/models/case_model.dart';
import 'package:dwell/features/cases/models/reports_creation_notice.dart';
import 'package:dwell/features/cases/pages/cases_page.dart';
import 'package:dwell/features/cases/widgets/list/case_creation_toast.dart';
import 'package:dwell/features/cases/widgets/list/case_search_tabs.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/case_creation_test_harness.dart';

ReportsCreationNotice notice({bool demo = true}) {
  final input = EvidenceAnalysisInput(CaseDraftView(CaseDraft()), []);
  return ReportsCreationNotice.fromResult(
    demo
        ? CaseCreationResult.demo(input)
        : CaseCreationResult.confirmed(
            input,
            mockCases.first,
            originalFileSaved: true,
            analysisAttached: true,
            tamperProtectionConfirmed: false,
          ),
  );
}

void main() {
  setUpAll(() async {
    await loadCreationTestFonts();
    await (FontLoader('packages/lucide_icons_flutter/Lucide')..addFont(
          rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
        ))
        .load();
  });
  for (final demo in [false, true]) {
    testWidgets(
      'Reports consumes ${demo ? "demo" : "confirmed"} event once, selects Logged and fades out',
      (tester) async {
        final h = await CreationHarness.start(tester, direct: true);
        final event = notice(demo: demo);
        h.router.goNamed('cases', extra: event);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<CaseStatusTabs>(find.byType(CaseStatusTabs))
              .selectedStatus,
          CaseStatus.logged,
        );
        expect(
          tester.widget<BottomNavBar>(find.byType(BottomNavBar)).currentIndex,
          1,
        );
        expect(find.byType(CaseCreationToast), findsOneWidget);
        expect(
          find.text(demo ? 'Demo case created' : 'Case created successfully'),
          findsOneWidget,
        );
        expect(find.byType(SnackBar), findsNothing);
        h.router.goNamed('cases', extra: event);
        await tester.pump();
        expect(find.byType(CaseCreationToast), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 2500));
        await tester.pumpAndSettle();
        expect(find.byType(CaseCreationToast), findsNothing);
        h.router.goNamed('cases', extra: event);
        await tester.pumpAndSettle();
        expect(find.byType(CaseCreationToast), findsNothing);
        h.router.goNamed('cases', extra: notice(demo: demo));
        await tester.pumpAndSettle();
        expect(find.byType(CaseCreationToast), findsOneWidget);
        h.router.goNamed('cases');
        await tester.pumpAndSettle();
        expect(find.byType(CaseCreationToast), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Normal entry stays quiet; branch and status changes cancel toast without replay',
    (tester) async {
      final h = await CreationHarness.start(tester, direct: true);
      h.router.goNamed('cases');
      await tester.pumpAndSettle();
      expect(find.byType(CaseCreationToast), findsNothing);
      expect(
        tester
            .widget<CaseStatusTabs>(find.byType(CaseStatusTabs))
            .selectedStatus,
        isNull,
      );
      h.router.goNamed('cases', extra: notice());
      await tester.pumpAndSettle();
      tester.widget<BottomNavBar>(find.byType(BottomNavBar)).onTap(2);
      await tester.pumpAndSettle();
      tester.widget<BottomNavBar>(find.byType(BottomNavBar)).onTap(1);
      await tester.pumpAndSettle();
      expect(find.byType(CaseCreationToast), findsNothing);
      h.router.goNamed('cases', extra: notice());
      await tester.pumpAndSettle();
      tester
          .widget<CaseStatusTabs>(find.byType(CaseStatusTabs))
          .onChanged(CaseStatus.active);
      await tester.pumpAndSettle();
      expect(find.byType(CaseCreationToast), findsNothing);
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(1280, 800),
  ]) {
    testWidgets('Toast fits $size at 2x text and avoids New Case', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: CasesPage(creationNotice: notice(demo: false)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      final toast = tester.getRect(
        find.byKey(const ValueKey('reports-creation-toast')),
      );
      final button = tester.getRect(
        find.widgetWithText(ElevatedButton, 'New Case'),
      );
      expect(toast.overlaps(button), false);
      expect(toast.left, greaterThanOrEqualTo(0));
      expect(toast.right, lessThanOrEqualTo(size.width));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    });
  }

  if (const bool.fromEnvironment('DWELL_REPORTS_TOAST_PREVIEW')) {
    testWidgets('Reports toast design preview', (tester) async {
      final h = await CreationHarness.start(
        tester,
        direct: true,
        size: const Size(390, 844),
      );
      tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
      addTearDown(tester.view.resetPadding);
      h.router.goNamed('cases', extra: notice(demo: false));
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first,
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        await File(
          '${Directory.systemTemp.path}/dwell-diagnostics/reports-toast.png',
        ).writeAsBytes(data!.buffer.asUint8List());
      });
      expect(tester.takeException(), isNull);
    });
  }
}
