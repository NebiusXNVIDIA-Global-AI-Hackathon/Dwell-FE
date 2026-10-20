import 'neighbor_post.dart';

/// 태그 하나와 그 태그가 달린 글 수
class TagCount {
  final String tag;
  final int postCount;

  const TagCount({required this.tag, required this.postCount});
}

/// 제목으로 걸린 글 — 제안 목록에서 바로 상세로 보낸다
class TitleSuggestion {
  final int postId;
  final String title;
  final PostBoard board;
  final PostFloorBand floorBand;

  const TitleSuggestion({
    required this.postId,
    required this.title,
    required this.board,
    required this.floorBand,
  });

  String get subtitle =>
      '${board == PostBoard.tips ? 'Tips' : 'Free Board'} · '
      '${floorBand.label.toLowerCase()}';
}

/// 검색창이 받는 제안 묶음
class TagSuggestions {
  final List<TagCount> items;
  final bool exactMatch;
  final List<TitleSuggestion> titles;

  const TagSuggestions({
    this.items = const [],
    this.exactMatch = false,
    this.titles = const [],
  });

  bool get isEmpty => items.isEmpty && titles.isEmpty;
}

/// 태그 결과 화면 머리말 — `24 posts · 3 related to your case`
class TagSummary {
  final String tag;
  final int postCount;
  final int relatedToMyCase;

  const TagSummary({
    required this.tag,
    required this.postCount,
    this.relatedToMyCase = 0,
  });
}
