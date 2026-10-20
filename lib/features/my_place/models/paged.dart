/// 페이지 단위 목록 — 커뮤니티 · 집주인 언급 글 · HPD 기록
class Paged<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final bool hasNext;

  const Paged({
    required this.content,
    required this.totalElements,
    this.page = 0,
    this.size = 20,
    this.hasNext = false,
  });

  static Paged<T> empty<T>() => Paged<T>(content: const [], totalElements: 0);
}
