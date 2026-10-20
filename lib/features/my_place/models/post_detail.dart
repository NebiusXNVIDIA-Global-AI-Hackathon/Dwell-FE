import 'neighbor_post.dart';

/// 게시물 작성자 — 서버가 표시 문구를 그대로 내려준다 (`Middle Floor neighbor`)
class PostAuthor {
  final String label;
  final bool isMe;

  const PostAuthor({required this.label, this.isMe = false});
}

/// 본문 사진 — 서버는 짧게 유효한 URL 을 준다
class PostImage {
  final int fileId;
  final String url;

  const PostImage({required this.fileId, required this.url});
}

/// 댓글 — 닉네임은 서버가 주고, 층은 구간까지만 보인다
class PostReply {
  final int replyId;
  final String nickname;
  final String initials;
  final PostFloorBand floorBand;
  final String content;
  final DateTime createdAt;
  final bool isMe;

  const PostReply({
    required this.replyId,
    required this.nickname,
    required this.initials,
    required this.floorBand,
    required this.content,
    required this.createdAt,
    this.isMe = false,
  });

  String get authorLine => '$nickname · ${floorBand.label}';
}

/// 게시물 상세 — 목록 카드보다 본문 · 사진 · 댓글이 더 있다
class PostDetail {
  final int postId;
  final PostBoard board;
  final String title;
  final String content;
  final PostAuthor author;
  final List<String> tags;
  final List<PostImage> images;
  final int likeCount;
  final bool likedByMe;
  final DateTime createdAt;
  final List<PostReply> replies;

  const PostDetail({
    required this.postId,
    required this.board,
    required this.title,
    required this.content,
    required this.author,
    required this.tags,
    required this.images,
    required this.likeCount,
    required this.likedByMe,
    required this.createdAt,
    required this.replies,
  });

  bool get isMine => author.isMe;
}
