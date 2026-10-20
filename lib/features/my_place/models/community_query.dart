/// 커뮤니티 목록 탭 — 서버의 board 파라미터와 1:1
enum CommunityTab {
  recommended('Recommended'),
  freeBoard('Free Board'),
  tips('Tips');

  const CommunityTab(this.label);

  final String label;
}

/// 목록 · 태그 결과가 함께 쓰는 조회 조건
class CommunityQuery {
  final CommunityTab tab;

  /// `#` 포함. 비어 있으면 태그로 거르지 않는다
  final String tag;
  final int page;
  final int size;

  const CommunityQuery({
    this.tab = CommunityTab.recommended,
    this.tag = '',
    this.page = 0,
    this.size = 20,
  });

  CommunityQuery copyWith({CommunityTab? tab, String? tag, int? page}) =>
      CommunityQuery(
        tab: tab ?? this.tab,
        tag: tag ?? this.tag,
        page: page ?? this.page,
        size: size,
      );

  @override
  bool operator ==(Object other) =>
      other is CommunityQuery &&
      other.tab == tab &&
      other.tag == tag &&
      other.page == page &&
      other.size == size;

  @override
  int get hashCode => Object.hash(tab, tag, page, size);
}
