import 'package:dwell/app.dart';
import 'package:dwell/core/router.dart';
import 'package:dwell/features/auth/providers/session_provider.dart';
import 'package:dwell/features/case_detail/presentation/screens/case_detail_screen.dart';
import 'package:dwell/features/case_detail/state/case_detail_controller.dart';
import 'package:dwell/features/cases/widgets/list/case_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'case_creation_test_harness.dart';

const caseId = 'mock-case-003';

class DetailHarness {
  DetailHarness(this.tester, this.container, this.router, this.id);
  final WidgetTester tester;
  final ProviderContainer container;
  final GoRouter router;
  final String id;

  CaseDetailController get controller =>
      container.read(caseDetailProvider(id).notifier);

  static Future<DetailHarness> open(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    bool fromList = false,
    String id = caseId,
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
    final h = DetailHarness(tester, container, router, id);
    if (fromList) {
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is CaseCard && widget.caseItem.id == id,
        ),
      );
    } else {
      router.pushNamed('case-detail', pathParameters: {'caseId': id});
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
    for (final item in container.read(caseDetailProvider(id))!.checklist)
      item.text,
  ];
}

Future<void> loadCaseDetailTestFonts() async {
  await loadCreationTestFonts();
  await (FontLoader('packages/lucide_icons_flutter/Lucide')..addFont(
        rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
      ))
      .load();
}
