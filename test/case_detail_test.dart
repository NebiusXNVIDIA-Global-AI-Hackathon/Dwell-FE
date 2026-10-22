import 'package:dwell/app.dart';
import 'package:dwell/core/router.dart';
import 'package:dwell/features/auth/providers/session_provider.dart';
import 'package:dwell/features/case_detail/presentation/screens/case_detail_screen.dart';
import 'package:dwell/features/case_detail/presentation/screens/case_timeline_screen.dart';
import 'package:dwell/features/case_detail/presentation/widgets/case_deleted_toast.dart';
import 'package:dwell/features/case_detail/presentation/widgets/delete_case_dialog.dart';
import 'package:dwell/features/case_detail/state/case_detail_controller.dart';
import 'package:dwell/features/cases/data/mock_cases.dart';
import 'package:dwell/features/cases/widgets/list/case_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/case_creation_test_harness.dart';

const caseId = 'mock-case-001';

class DetailHarness {
  DetailHarness(this.tester, this.container, this.router);
  final WidgetTester tester;
  final ProviderContainer container;
  final GoRouter router;

  static Future<DetailHarness> open(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    bool fromList = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    container.read(sessionProvider.notifier).enterDemo();
    final router = container.read(routerProvider);
    router.go('/cases');
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DwellApp()),
    );
    await tester.pumpAndSettle();
    final h = DetailHarness(tester, container, router);
    if (fromList) {
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is CaseCard && widget.caseItem.id == caseId,
        ),
      );
    } else {
      router.pushNamed('case-detail', pathParameters: {'caseId': caseId});
    }
    await tester.pumpAndSettle();
    expect(find.byType(CaseDetailScreen), findsOneWidget);
    return h;
  }

  Future<void> tap(Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  List<String> get checklist => [
    for (final item in container.read(caseDetailProvider(caseId))!.checklist)
      item.text,
  ];
}

void main() {
  setUpAll(() async {
    await loadCreationTestFonts();
    await (FontLoader('packages/lucide_icons_flutter/Lucide')..addFont(
          rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
        ))
        .load();
  });

  for (final size in const [Size(375, 812), Size(390, 844), Size(430, 932)]) {
    testWidgets('Case Detail lays out without overflow at $size', (
      tester,
    ) async {
      final h = await DetailHarness.open(tester, size: size);
      for (final text in [
        'Case Detail',
        'Current Status',
        'Send a notice',
        'Case Timeline',
        'Notified\nLandlord',
        'Checklist',
        'Take timestamped photos of the issue',
        '+ add checklist',
        'Evidence (1)',
        '1 item',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      final cta = find.text('View Case Analysis');
      await tester.ensureVisible(cta);
      await tester.pumpAndSettle();
      final ctaBox = tester.getRect(
        find.ancestor(of: cta, matching: find.byType(Material)).first,
      );
      // Left and right page margins match
      expect(ctaBox.left, size.width - ctaBox.right);
      expect(h.tester.takeException(), isNull);
    });
  }

  testWidgets('Cases card opens Case Detail', (tester) async {
    await DetailHarness.open(tester, fromList: true);
    expect(find.text('Case  #C-001'), findsOneWidget);
  });

  testWidgets('Checklist toggles, edits, adds and drops empty items', (
    tester,
  ) async {
    final h = await DetailHarness.open(tester);
    final first = h.container.read(caseDetailProvider(caseId))!.checklist[0];

    await h.tap(find.byKey(ValueKey('checklist-toggle-${first.id}')));
    expect(
      h.container.read(caseDetailProvider(caseId))!.checklist[0].isDone,
      isTrue,
    );

    await h.tap(find.text('Edit'));
    expect(find.byKey(ValueKey('checklist-edit-${first.id}')), findsOneWidget);
    await h.tap(find.byKey(ValueKey('checklist-edit-${first.id}')));
    await tester.enterText(find.byType(TextField), 'Call the super');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(h.checklist.first, 'Call the super');

    await h.tap(find.text('Edit'));
    await h.tap(find.text('+ add checklist'));
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Keep receipts');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(h.checklist.last, 'Keep receipts');

    await h.tap(find.text('+ add checklist'));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(h.checklist, hasLength(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Swipe reveals delete action and removes the item', (
    tester,
  ) async {
    final h = await DetailHarness.open(tester);
    final tile = find.text('Send written notice to your landlord');
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.drag(tile, const Offset(-120, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Delete item'));
    await tester.pumpAndSettle();
    expect(
      h.checklist,
      isNot(contains('Send written notice to your landlord')),
    );
  });

  testWidgets('View Detail opens the vertical timeline', (tester) async {
    final h = await DetailHarness.open(tester);
    await h.tap(find.text('View Detail'));
    expect(find.byType(CaseTimelineScreen), findsOneWidget);
    expect(find.text('Landlord Notified'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Delete confirms, returns to Cases and shows the toast', (
    tester,
  ) async {
    final h = await DetailHarness.open(tester);
    final before = mockCases.length;

    await h.tap(find.byTooltip('Case options'));
    expect(find.text('Add Evidence'), findsOneWidget);
    await h.tap(find.text('Delete'));
    expect(find.byType(DeleteCaseDialog), findsOneWidget);

    await h.tap(find.text('Cancel'));
    expect(find.byType(CaseDetailScreen), findsOneWidget);

    await h.tap(find.byTooltip('Case options'));
    await h.tap(find.text('Delete'));
    await tester.tap(find.text('Yes, Delete this case'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CaseDetailScreen), findsNothing);
    expect(find.byType(CaseDeletedToast), findsOneWidget);
    expect(find.text('Case deleted'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is CaseCard && widget.caseItem.id == caseId,
      ),
      findsNothing,
    );
    expect(mockCases.length, before);

    await tester.pump(const Duration(milliseconds: 300));
    final fade = find.ancestor(
      of: find.text('Case deleted'),
      matching: find.byType(FadeTransition),
    );
    expect(tester.widget<FadeTransition>(fade.first).opacity.value, 1);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(CaseDeletedToast), findsNothing);
  });
}
