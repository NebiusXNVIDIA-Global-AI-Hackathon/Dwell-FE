import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dwell/features/my_place/my_place_page.dart';
import 'package:dwell/features/my_place/pages/check_my_unit_page.dart';

Future<void> pumpPage(
  WidgetTester tester,
  Widget page, {
  double textScale = 1,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: page,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('my place shows the address and the rising issue area', (
    tester,
  ) async {
    await pumpPage(tester, const MyPlacePage());

    expect(find.textContaining('245 W 107th St'), findsOneWidget);
    expect(find.text('Rising Issue!!!'), findsWidgets);
    expect(find.text('Building Signals'), findsOneWidget);
    expect(find.text('Neighbor Community'), findsOneWidget);
  });

  testWidgets('my place survives a large text scale on a narrow screen', (
    tester,
  ) async {
    await pumpPage(
      tester,
      const MyPlacePage(),
      textScale: 1.8,
      size: const Size(320, 844),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('check my unit keeps next disabled until something is checked', (
    tester,
  ) async {
    await pumpPage(tester, const CheckMyUnitPage(signalId: 102));

    expect(
      find.text('Roaches seen in the kitchen or bathroom'),
      findsOneWidget,
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Your unit might be affected'), findsNothing);

    await tester.tap(find.text('Roaches seen in the kitchen or bathroom'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Your unit might be affected'), findsOneWidget);
    expect(find.text('Talk to Deaver'), findsOneWidget);
    expect(find.text('Create Case'), findsOneWidget);
  });
}
