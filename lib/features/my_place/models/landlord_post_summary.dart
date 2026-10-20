import 'data_status.dart';
import 'neighbor_post.dart';

/// Insights Tenants 탭 — 집주인 언급 글 집계
class LandlordPostSummary {
  final DataStatus status;
  final int postCount;

  /// 요약을 보여주는 최소 글 수
  final int minimumRequired;

  /// 분류별 글 수 — 타일과 탭이 같은 값을 본다
  final Map<PostTopic, int> topicCounts;

  /// 좋아요 많은 순 3개. 데이터가 부족하면 빈 목록
  final List<NeighborPost> previewPosts;

  const LandlordPostSummary({
    required this.status,
    required this.postCount,
    required this.minimumRequired,
    required this.topicCounts,
    this.previewPosts = const [],
  });

  int countOf(PostTopic topic) => topicCounts[topic] ?? 0;
}
