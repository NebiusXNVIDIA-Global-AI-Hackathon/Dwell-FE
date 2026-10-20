import 'issue_category.dart';
import 'neighbor_post.dart';

/// 게시 기간 필터
enum PostedWindow {
  lastMonth('Last month'),
  last6Months('Last 6 months'),
  lastYear('Last year');

  const PostedWindow(this.label);

  final String label;
}

enum PostSort {
  newest('Newest'),
  oldest('Oldest');

  const PostSort(this.label);

  final String label;
}

/// Posts about landlord 의 검색 · 필터 · 정렬 — 서버 쿼리와 같은 모양
class LandlordPostQuery {
  final String query;
  final Set<PostTopic> topics;
  final Set<IssueCategory> issueTypes;
  final Set<PostFloorBand> floorBands;
  final PostedWindow? posted;
  final PostSort sort;
  final int page;
  final int size;

  const LandlordPostQuery({
    this.query = '',
    this.topics = const {},
    this.issueTypes = const {},
    this.floorBands = const {},
    this.posted,
    this.sort = PostSort.newest,
    this.page = 0,
    this.size = 20,
  });

  /// 적용 칩이 하나라도 있는지 — 검색어는 칩이 아니다
  bool get hasFilters =>
      topics.isNotEmpty ||
      issueTypes.isNotEmpty ||
      floorBands.isNotEmpty ||
      posted != null;

  LandlordPostQuery copyWith({
    String? query,
    Set<PostTopic>? topics,
    Set<IssueCategory>? issueTypes,
    Set<PostFloorBand>? floorBands,
    PostedWindow? posted,
    bool clearPosted = false,
    PostSort? sort,
    int? page,
    int? size,
  }) {
    return LandlordPostQuery(
      query: query ?? this.query,
      topics: topics ?? this.topics,
      issueTypes: issueTypes ?? this.issueTypes,
      floorBands: floorBands ?? this.floorBands,
      posted: clearPosted ? null : (posted ?? this.posted),
      sort: sort ?? this.sort,
      page: page ?? this.page,
      size: size ?? this.size,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LandlordPostQuery &&
      other.query == query &&
      other.sort == sort &&
      other.page == page &&
      other.size == size &&
      other.posted == posted &&
      _sameSet(other.topics, topics) &&
      _sameSet(other.issueTypes, issueTypes) &&
      _sameSet(other.floorBands, floorBands);

  @override
  int get hashCode => Object.hash(
    query,
    sort,
    page,
    size,
    posted,
    Object.hashAllUnordered(topics),
    Object.hashAllUnordered(issueTypes),
    Object.hashAllUnordered(floorBands),
  );

  static bool _sameSet<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);
}
