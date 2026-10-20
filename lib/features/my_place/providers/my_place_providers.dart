import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/building_signals_mock.dart';
import '../data/insights_mock.dart';
import '../data/landlord_posts_mock.dart';
import '../data/neighbor_posts_mock.dart';
import '../models/building_signal.dart';
import '../models/hpd_history.dart';
import '../models/inspection.dart';
import '../models/landlord_insight.dart';
import '../models/landlord_post_query.dart';
import '../models/landlord_post_summary.dart';
import '../models/neighbor_post.dart';
import '../models/owner_portfolio.dart';
import '../models/paged.dart';
import '../models/place_summary.dart';
import '../models/records_insight.dart';

/// 목업을 서버 응답 자리에 끼워 둔다 — 연동 시 이 함수들만 교체
final placeSummaryProvider = FutureProvider<PlaceSummary>(
  (ref) async => PlaceSummary(
    address: demoBuildingAddress,
    bbl: demoBuildingBbl,
    risingIssues: mockRisingSignals,
  ),
);

final buildingSignalsProvider = FutureProvider<BuildingSignals>(
  (ref) async => mockBuildingSignals,
);

final signalDetailProvider = FutureProvider.family<SignalDetail?, int>(
  (ref, signalId) async => signalDetailFor(signalId),
);

final inspectionGuideProvider = FutureProvider.family<InspectionGuide?, int>(
  (ref, signalId) async => mockInspectionGuides[signalId],
);

final landlordInsightProvider = FutureProvider<LandlordInsight>(
  (ref) async =>
      showLowDataDemo ? mockLandlordInsightLowData : mockLandlordInsight,
);

final recordsInsightProvider = FutureProvider<RecordsInsight>(
  (ref) async =>
      showLowDataDemo ? mockRecordsInsightLowData : mockRecordsInsight,
);

final hpdHistoryProvider = FutureProvider<HpdHistory>(
  (ref) async => mockHpdHistory,
);

/// 같은 소유주 집계는 서버에 없다 — 목업만
final ownerPortfolioProvider = Provider<OwnerPortfolio>(
  (ref) => showLowDataDemo ? mockOwnerPortfolioLowData : mockOwnerPortfolio,
);

/// 게시물 원천 — 커뮤니티 · 시그널 상세 · Insights Tenants 가 전부 여기서 파생
final neighborPostsProvider =
    NotifierProvider<NeighborPostsNotifier, List<NeighborPost>>(
      NeighborPostsNotifier.new,
    );

class NeighborPostsNotifier extends Notifier<List<NeighborPost>> {
  @override
  List<NeighborPost> build() =>
      _sorted([...mockLandlordPosts, ...mockNeighborPosts]);

  void add(NeighborPost post) => state = [post, ...state];

  void replace(NeighborPost post) => state = [
    for (final item in state)
      if (item.postId == post.postId) post else item,
  ];

  void remove(int postId) => state = [
    for (final post in state)
      if (post.postId != postId) post,
  ];

  static List<NeighborPost> _sorted(List<NeighborPost> posts) =>
      posts..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

/// 집주인 언급 글만
final landlordPostsProvider = Provider<List<NeighborPost>>(
  (ref) => [
    for (final post in ref.watch(neighborPostsProvider))
      if (post.landlordTopic != null) post,
  ],
);

/// Tenants 탭 집계 — 타일 숫자와 탭 숫자가 한 곳에서 나온다
final landlordPostSummaryProvider = FutureProvider<LandlordPostSummary>((
  ref,
) async {
  final posts = ref.watch(landlordPostsProvider);
  return buildLandlordPostSummary(
    showLowDataDemo ? posts.take(2).toList() : posts,
  );
});

/// Posts about landlord — 검색 · 필터 · 정렬 · 페이징을 서버와 같은 순서로 적용
final landlordPostPageProvider =
    FutureProvider.family<Paged<NeighborPost>, LandlordPostQuery>((
      ref,
      query,
    ) async {
      final matched = [
        for (final post in ref.watch(landlordPostsProvider))
          if (_matches(post, query)) post,
      ];

      matched.sort(
        (a, b) => query.sort == PostSort.newest
            ? b.createdAt.compareTo(a.createdAt)
            : a.createdAt.compareTo(b.createdAt),
      );

      final start = query.page * query.size;
      final end = start + query.size;

      return Paged(
        content: matched.sublist(
          start.clamp(0, matched.length),
          end.clamp(0, matched.length),
        ),
        page: query.page,
        size: query.size,
        totalElements: matched.length,
        hasNext: end < matched.length,
      );
    });

bool _matches(NeighborPost post, LandlordPostQuery query) {
  if (query.topics.isNotEmpty && !query.topics.contains(post.landlordTopic)) {
    return false;
  }
  if (query.floorBands.isNotEmpty &&
      !query.floorBands.contains(post.floorBand)) {
    return false;
  }
  if (query.posted != null && post.createdAt.isBefore(_since(query.posted!))) {
    return false;
  }
  if (query.query.isEmpty) return true;

  final needle = query.query.toLowerCase();
  return post.title.toLowerCase().contains(needle) ||
      post.body.toLowerCase().contains(needle);
}

/// 데모 기준 시각에서 거슬러 올라간다
DateTime _since(PostedWindow window) {
  final now = DateTime(2026, 10, 14);
  return switch (window) {
    PostedWindow.lastMonth => now.subtract(const Duration(days: 30)),
    PostedWindow.last6Months => now.subtract(const Duration(days: 182)),
    PostedWindow.lastYear => now.subtract(const Duration(days: 365)),
  };
}
