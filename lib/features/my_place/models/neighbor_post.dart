enum PostBoard { freeBoard, tips }

/// 작성자 식별은 층 구간까지만 — 호수 · 정확한 층 금지
enum PostFloorBand {
  lower('Lower Floor'),
  middle('Middle Floor'),
  upper('Upper Floor');

  const PostFloorBand(this.label);

  final String label;
}

/// 집주인 언급 글의 분류
enum PostTopic {
  slowRepairs('Slow repairs'),
  noReply('No reply'),
  fixedWell('Fixed well');

  const PostTopic(this.label);

  final String label;
}

/// 커뮤니티 · 시그널 상세 · Insights Tenants · 집주인 언급 글이 공유
class NeighborPost {
  final int postId;
  final PostBoard board;
  final PostFloorBand floorBand;
  final String title;

  /// 목록용 한 줄 미리보기
  final String preview;
  final String body;

  /// `#` 포함
  final List<String> tags;
  final int likeCount;
  final int replyCount;
  final DateTime createdAt;

  /// 첫 이미지 — 서버는 짧게 유효한 URL 을 준다
  final String? thumbnailUrl;

  /// 집주인 언급 글만 값이 있다
  final PostTopic? landlordTopic;
  final bool isMine;

  const NeighborPost({
    required this.postId,
    required this.board,
    required this.floorBand,
    required this.title,
    required this.preview,
    required this.body,
    required this.tags,
    required this.likeCount,
    required this.replyCount,
    required this.createdAt,
    this.thumbnailUrl,
    this.landlordTopic,
    this.isMine = false,
  });

  bool get isTip => board == PostBoard.tips;
}
