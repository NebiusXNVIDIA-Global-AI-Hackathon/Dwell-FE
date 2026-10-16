enum PostBoard { freeBoard, tips }

/// 작성자 식별은 층 밴드까지만 — 호수 · 정확한 층 금지
enum PostFloorBand { lower, middle, upper }

/// 집주인 언급 글의 주제
enum PostTopic { slowRepairs, noReply, fixedWell }

/// 커뮤니티 · 시그널 상세 · Insights Tenants · 집주인 언급 글이 공유
class NeighborPost {
  final String id;
  final PostBoard board;
  final PostFloorBand floorBand;
  final String title;
  final String excerpt;
  final String body;
  final List<String> tags;
  final int likes;
  final int replyCount;
  final DateTime postedAt;
  final String? thumbnailPath;

  /// 집주인 언급 글만 값이 있다
  final PostTopic? topic;
  final bool isMine;

  const NeighborPost({
    required this.id,
    required this.board,
    required this.floorBand,
    required this.title,
    required this.excerpt,
    required this.body,
    required this.tags,
    required this.likes,
    required this.replyCount,
    required this.postedAt,
    this.thumbnailPath,
    this.topic,
    this.isMine = false,
  });
}
