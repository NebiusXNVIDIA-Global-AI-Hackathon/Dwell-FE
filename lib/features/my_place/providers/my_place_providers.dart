import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/building_issues_mock.dart';
import '../data/insights_mock.dart';
import '../data/landlord_posts_mock.dart';
import '../data/neighbor_posts_mock.dart';
import '../models/building_issue.dart';
import '../models/building_records.dart';
import '../models/landlord_record.dart';
import '../models/neighbor_post.dart';
import '../models/owner_portfolio.dart';

/// 건물 이슈 — 0개면 All clear 카드, 2개 이상이면 캐러셀
final buildingIssuesProvider = Provider<List<BuildingIssue>>(
  (ref) => mockBuildingIssues,
);

final buildingIssueProvider = Provider.family<BuildingIssue?, String>((
  ref,
  issueId,
) {
  for (final issue in ref.watch(buildingIssuesProvider)) {
    if (issue.id == issueId) return issue;
  }
  return null;
});

final landlordRecordProvider = Provider<LandlordRecord>(
  (ref) => mockLandlordRecord,
);

final buildingRecordsProvider = Provider<BuildingRecords>(
  (ref) => mockBuildingRecords,
);

final ownerPortfolioProvider = Provider<OwnerPortfolio>(
  (ref) => mockOwnerPortfolio,
);

/// 게시물 원천 — 커뮤니티 · 시그널 상세 · Insights Tenants · 집주인 언급 글이 전부 여기서 파생
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
      if (item.id == post.id) post else item,
  ];

  void remove(String id) => state = [
    for (final post in state)
      if (post.id != id) post,
  ];

  static List<NeighborPost> _sorted(List<NeighborPost> posts) =>
      posts..sort((a, b) => b.postedAt.compareTo(a.postedAt));
}

/// 이슈 태그로 걸러낸 글 — 시그널 상세
final postsByIssueProvider = Provider.family<List<NeighborPost>, String>((
  ref,
  issueId,
) {
  final issue = ref.watch(buildingIssueProvider(issueId));
  if (issue == null) return const [];

  final wanted = issue.postTags.toSet();
  return [
    for (final post in ref.watch(neighborPostsProvider))
      if (post.tags.any(wanted.contains)) post,
  ];
});

/// 집주인 언급 글만 — Insights Tenants · Posts about landlord
final landlordPostsProvider = Provider<List<NeighborPost>>(
  (ref) => [
    for (final post in ref.watch(neighborPostsProvider))
      if (post.topic != null) post,
  ],
);

/// 주제별 개수 — 집계 타일과 주제 탭이 같은 값을 본다
final landlordPostCountsProvider = Provider<Map<PostTopic, int>>((ref) {
  final counts = {for (final topic in PostTopic.values) topic: 0};
  for (final post in ref.watch(landlordPostsProvider)) {
    counts[post.topic!] = counts[post.topic]! + 1;
  }
  return counts;
});
