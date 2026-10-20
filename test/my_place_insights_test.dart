import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dwell/core/theme.dart';
import 'package:dwell/features/my_place/data/insights_mock.dart';
import 'package:dwell/features/my_place/pages/building_insights_page.dart';
import 'package:dwell/features/my_place/pages/hpd_history_page.dart';
import 'package:dwell/features/my_place/pages/landlord_posts_page.dart';
import 'package:dwell/features/my_place/providers/my_place_providers.dart';
import 'package:dwell/features/my_place/widgets/common/segmented_tabs.dart';
import 'package:dwell/features/my_place/widgets/community/post_filter_sheet.dart';

Future<void> pumpTree(WidgetTester tester, Widget tree) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(tree);
  await tester.pumpAndSettle();
}

Widget app(Widget page) =>
    MaterialApp(theme: buildTheme(Brightness.light), home: page);

Future<void> pumpPage(WidgetTester tester, Widget page) =>
    pumpTree(tester, ProviderScope(child: app(page)));

/// 기록이 충분한 건물 — 목업 스위치와 무관하게 전체 데이터를 넣는다
Future<void> pumpFullData(WidgetTester tester, Widget page) => pumpTree(
  tester,
  ProviderScope(
    overrides: [
      landlordInsightProvider.overrideWith((ref) async => mockLandlordInsight),
      recordsInsightProvider.overrideWith((ref) async => mockRecordsInsight),
      ownerPortfolioProvider.overrideWithValue(mockOwnerPortfolio),
      landlordPostSummaryProvider.overrideWith(
        (ref) async =>
            buildLandlordPostSummary(ref.watch(landlordPostsProvider)),
      ),
    ],
    child: app(page),
  ),
);

/// 기록이 부족한 건물 — 네 탭이 모두 저데이터로 갈린다
Future<void> pumpLowData(WidgetTester tester, Widget page) => pumpTree(
  tester,
  ProviderScope(
    overrides: [
      landlordInsightProvider.overrideWith(
        (ref) async => mockLandlordInsightLowData,
      ),
      recordsInsightProvider.overrideWith(
        (ref) async => mockRecordsInsightLowData,
      ),
      ownerPortfolioProvider.overrideWithValue(mockOwnerPortfolioLowData),
      landlordPostsProvider.overrideWithValue(const []),
    ],
    child: app(page),
  ),
);

void main() {
  testWidgets('each insights tab shows its own card', (tester) async {
    await pumpFullData(tester, const BuildingInsightsPage());

    expect(find.text('Landlord track record'), findsOneWidget);
    expect(find.text('Slow to fix'), findsOneWidget);
    expect(find.text('Follow-up timer'), findsOneWidget);
    expect(find.text('Not a landlord rating.'), findsOneWidget);

    await tester.tap(find.text('Tenants'));
    await tester.pumpAndSettle();
    expect(find.text('Neighbor posts'), findsOneWidget);
    expect(find.text('What neighbors mention'), findsOneWidget);

    await tester.tap(find.text('Records'));
    await tester.pumpAndSettle();
    expect(find.text('Building records'), findsOneWidget);
    expect(find.text('Complaints by category'), findsOneWidget);

    await tester.tap(find.text('Owner'));
    await tester.pumpAndSettle();
    expect(find.text('Same owner'), findsOneWidget);
    expect(find.textContaining('Violations across all'), findsOneWidget);
  });

  testWidgets('thin records never turn into a score', (tester) async {
    await pumpLowData(tester, const BuildingInsightsPage());

    expect(find.text('Not enough data'), findsOneWidget);
    expect(find.text('1 of 3 fixed violations'), findsOneWidget);
    expect(find.text('1 of 3 fixed violations'), findsOneWidget);
    expect(find.text('2 more needed'), findsOneWidget);
    // 단축되지 않은 타이머는 기본값만 보여준다
    expect(find.text('72h'), findsOneWidget);
    expect(find.text('48h'), findsNothing);

    await tester.tap(find.text('Records'));
    await tester.pumpAndSettle();
    expect(
      find.text('Too few records to show categories, repeats or trends.'),
      findsOneWidget,
    );
    expect(find.text('2 of 3 records'), findsOneWidget);
    expect(find.text('Trends need 3+'), findsOneWidget);
    expect(find.text('Complaints by category'), findsNothing);

    await tester.tap(find.text('Owner'));
    await tester.pumpAndSettle();
    expect(find.text('No other buildings found'), findsOneWidget);

    await tester.tap(find.text('Tenants'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 3 posts'), findsOneWidget);
    expect(find.text('Go to Neighbor Community'), findsOneWidget);
  });

  testWidgets('topic tabs narrow the landlord post list', (tester) async {
    await pumpPage(tester, const LandlordPostsPage());

    expect(find.text('All(9)'), findsOneWidget);
    expect(
      find.text('Landlord took 3 weeks to send a plumber'),
      findsOneWidget,
    );

    // 탭 줄은 가로로 스크롤된다 — 보이게 만든 뒤 누른다
    await tester.scrollUntilVisible(
      find.text('Fixed well(1)'),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Fixed well(1)'));
    await tester.pumpAndSettle();
    expect(
      find.text('Pipe was replaced properly after the second visit'),
      findsOneWidget,
    );
    expect(find.text('Landlord took 3 weeks to send a plumber'), findsNothing);
  });

  testWidgets('sheet filters show as chips and reset leaves the tab alone', (
    tester,
  ) async {
    await pumpPage(tester, const LandlordPostsPage());

    await tester.scrollUntilVisible(
      find.text('Slow repairs(5)'),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Slow repairs(5)'));
    await tester.pumpAndSettle();

    // 탭이 보여주는 조건은 칩으로 겹쳐 띄우지 않는다
    expect(find.text('Reset'), findsNothing);

    await tester.tap(find.byIcon(LucideIcons.funnel));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(PostFilterSheet),
        matching: find.text('Middle Floor'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();

    expect(find.text('Reset'), findsOneWidget);
    expect(
      find.text('Still waiting on the radiator since September'),
      findsNothing,
    );

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.text('Reset'), findsNothing);
    expect(
      find.text('Still waiting on the radiator since September'),
      findsOneWidget,
    );
  });

  testWidgets('hpd history only designs the overview tab', (tester) async {
    await pumpPage(tester, const HpdHistoryPage());

    expect(find.text('Violations by class'), findsOneWidget);
    expect(find.text('Per quarter'), findsOneWidget);
    expect(find.text('6 open · 12 closed'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedTabs),
        matching: find.text('Complaints'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsOneWidget);
  });
}
