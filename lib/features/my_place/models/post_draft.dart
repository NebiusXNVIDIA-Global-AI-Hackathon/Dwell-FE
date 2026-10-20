import 'neighbor_post.dart';

/// 작성 · 수정 공용 입력값 — 서버의 생성 · 수정 요청과 같은 모양
class PostDraft {
  final PostBoard board;
  final String title;
  final String content;
  final List<String> tags;
  final List<int> imageFileIds;

  const PostDraft({
    this.board = PostBoard.freeBoard,
    this.title = '',
    this.content = '',
    this.tags = const [],
    this.imageFileIds = const [],
  });

  /// 와프 기준 본문 상한
  static const contentLimit = 1000;

  bool get canSubmit => title.trim().isNotEmpty && content.trim().isNotEmpty;

  PostDraft copyWith({
    PostBoard? board,
    String? title,
    String? content,
    List<String>? tags,
    List<int>? imageFileIds,
  }) => PostDraft(
    board: board ?? this.board,
    title: title ?? this.title,
    content: content ?? this.content,
    tags: tags ?? this.tags,
    imageFileIds: imageFileIds ?? this.imageFileIds,
  );
}
