import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/building_signals_mock.dart';
import '../data/community_mock.dart';
import '../data/insights_mock.dart';
import '../data/landlord_posts_mock.dart';
import '../data/neighbor_posts_mock.dart';
import '../models/building_signal.dart';
import '../models/community_query.dart';
import '../models/hpd_history.dart';
import '../models/inspection.dart';
import '../models/landlord_insight.dart';
import '../models/landlord_post_query.dart';
import '../models/landlord_post_summary.dart';
import '../models/neighbor_post.dart';
import '../models/owner_portfolio.dart';
import '../models/paged.dart';
import '../models/post_detail.dart';
import '../models/post_draft.dart';
import '../models/place_summary.dart';
import '../models/records_insight.dart';
import '../models/tag_suggestion.dart';

/// 목업을 서버 응답 자리에 끼워 둔다 — 연동 시 이 함수들만 교체
final placeSummaryProvider = FutureProvider<PlaceSummary>(
  (ref) async => PlaceSummary(
    address: demoBuildingAddress,
    bbl: demoBuildingBbl,
    risingIssues: mockRisingSignals,
  ),
);

final buildingSignalsProvider = FutureProvider<BuildingSignals>(
  (ref) async => mockBuildingSignals,
);

final signalDetailProvider = FutureProvider.family<SignalDetail?, int>(
  (ref, signalId) async => signalDetailFor(signalId),
);

final inspectionGuideProvider = FutureProvider.family<InspectionGuide?, int>(
  (ref, signalId) async => mockInspectionGuides[signalId],
);

final landlordInsightProvider = FutureProvider<LandlordInsight>(
  (ref) async =>
      showLowDataDemo ? mockLandlordInsightLowData : mockLandlordInsight,
);

final recordsInsightProvider = FutureProvider<RecordsInsight>(
  (ref) async =>
      showLowDataDemo ? mockRecordsInsightLowData : mockRecordsInsight,
);

final hpdHistoryProvider = FutureProvider<HpdHistory>(
  (ref) async => mockHpdHistory,
);

/// 같은 소유주 집계는 서버에 없다 — 목업만
final ownerPortfolioProvider = Provider<OwnerPortfolio>(
  (ref) => showLowDataDemo ? mockOwnerPortfolioLowData : mockOwnerPortfolio,
);

/// 게시물 원천 — 커뮤니티 · 시그널 상세 · Insights Tenants 가 전부 여기서 파생
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
      if (item.postId == post.postId) post else item,
  ];

  void remove(int postId) => state = [
    for (final post in state)
      if (post.postId != postId) post,
  ];

  /// 작성 · 수정 공용 — 서버가 돌려줄 postId 자리를 목업이 채운다
  int submit(PostDraft draft, {int? postId}) {
    final preview = draft.content.replaceAll('\n', ' ').trim();
    final existing = postId == null ? null : _byId(postId);

    if (existing != null) {
      replace(
        NeighborPost(
          postId: existing.postId,
          board: draft.board,
          floorBand: existing.floorBand,
          title: draft.title.trim(),
          preview: preview,
          body: draft.content.trim(),
          tags: draft.tags,
          likeCount: existing.likeCount,
          replyCount: existing.replyCount,
          createdAt: existing.createdAt,
          thumbnailUrl: existing.thumbnailUrl,
          landlordTopic: existing.landlordTopic,
          isMine: true,
        ),
      );
      return existing.postId;
    }

    final id =
        state.fold(0, (max, post) => post.postId > max ? post.postId : max) + 1;
    add(
      NeighborPost(
        postId: id,
        board: draft.board,
        floorBand: mockMyFloorBand,
        title: draft.title.trim(),
        preview: preview,
        body: draft.content.trim(),
        tags: draft.tags,
        likeCount: 0,
        replyCount: 0,
        createdAt: DateTime.now(),
        isMine: true,
      ),
    );
    return id;
  }

  /// 좋아요 · 댓글 수는 상세에서 바뀌어도 목록이 같이 따라와야 한다
  void bumpLike(int postId, int delta) => _bump(postId, likes: delta);

  void bumpReply(int postId) => _bump(postId, replies: 1);

  void _bump(int postId, {int likes = 0, int replies = 0}) {
    final post = _byId(postId);
    if (post == null) return;
    replace(
      NeighborPost(
        postId: post.postId,
        board: post.board,
        floorBand: post.floorBand,
        title: post.title,
        preview: post.preview,
        body: post.body,
        tags: post.tags,
        likeCount: post.likeCount + likes,
        replyCount: post.replyCount + replies,
        createdAt: post.createdAt,
        thumbnailUrl: post.thumbnailUrl,
        landlordTopic: post.landlordTopic,
        isMine: post.isMine,
      ),
    );
  }

  NeighborPost? _byId(int postId) {
    for (final post in state) {
      if (post.postId == postId) return post;
    }
    return null;
  }

  static List<NeighborPost> _sorted(List<NeighborPost> posts) =>
      posts..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

/// 집주인 언급 글만
final landlordPostsProvider = Provider<List<NeighborPost>>(
  (ref) => [
    for (final post in ref.watch(neighborPostsProvider))
      if (post.landlordTopic != null) post,
  ],
);

/// Tenants 탭 집계 — 타일 숫자와 탭 숫자가 한 곳에서 나온다
final landlordPostSummaryProvider = FutureProvider<LandlordPostSummary>((
  ref,
) async {
  final posts = ref.watch(landlordPostsProvider);
  return buildLandlordPostSummary(
    showLowDataDemo ? posts.take(2).toList() : posts,
  );
});

/// Posts about landlord — 검색 · 필터 · 정렬 · 페이징을 서버와 같은 순서로 적용
final landlordPostPageProvider =
    FutureProvider.family<Paged<NeighborPost>, LandlordPostQuery>((
      ref,
      query,
    ) async {
      final matched = [
        for (final post in ref.watch(landlordPostsProvider))
          if (_matches(post, query)) post,
      ];

      matched.sort(
        (a, b) => query.sort == PostSort.newest
            ? b.createdAt.compareTo(a.createdAt)
            : a.createdAt.compareTo(b.createdAt),
      );

      final start = query.page * query.size;
      final end = start + query.size;

      return Paged(
        content: matched.sublist(
          start.clamp(0, matched.length),
          end.clamp(0, matched.length),
        ),
        page: query.page,
        size: query.size,
        totalElements: matched.length,
        hasNext: end < matched.length,
      );
    });

bool _matches(NeighborPost post, LandlordPostQuery query) {
  if (query.topics.isNotEmpty && !query.topics.contains(post.landlordTopic)) {
    return false;
  }
  if (query.floorBands.isNotEmpty &&
      !query.floorBands.contains(post.floorBand)) {
    return false;
  }
  if (query.posted != null && post.createdAt.isBefore(_since(query.posted!))) {
    return false;
  }
  if (query.query.isEmpty) return true;

  final needle = query.query.toLowerCase();
  return post.title.toLowerCase().contains(needle) ||
      post.body.toLowerCase().contains(needle);
}

/// 데모 기준 시각에서 거슬러 올라간다
DateTime _since(PostedWindow window) {
  final now = DateTime(2026, 10, 14);
  return switch (window) {
    PostedWindow.lastMonth => now.subtract(const Duration(days: 30)),
    PostedWindow.last6Months => now.subtract(const Duration(days: 182)),
    PostedWindow.lastYear => now.subtract(const Duration(days: 365)),
  };
}

/// 커뮤니티 목록 — 탭 · 태그 · 페이징을 서버와 같은 순서로 적용
final communityPostsProvider =
    FutureProvider.family<Paged<NeighborPost>, CommunityQuery>((
      ref,
      query,
    ) async {
      final matched = [
        for (final post in ref.watch(neighborPostsProvider))
          if (_matchesBoard(post, query.tab) &&
              (query.tag.isEmpty || post.tags.contains(query.tag)))
            post,
      ];

      // 추천은 반응이 많은 순, 보드 탭은 최신 순
      matched.sort(
        (a, b) => query.tab == CommunityTab.recommended
            ? _reactions(b).compareTo(_reactions(a))
            : b.createdAt.compareTo(a.createdAt),
      );

      final start = query.page * query.size;
      final end = start + query.size;

      return Paged(
        content: matched.sublist(
          start.clamp(0, matched.length),
          end.clamp(0, matched.length),
        ),
        page: query.page,
        size: query.size,
        totalElements: matched.length,
        hasNext: end < matched.length,
      );
    });

bool _matchesBoard(NeighborPost post, CommunityTab tab) => switch (tab) {
  CommunityTab.recommended => true,
  CommunityTab.freeBoard => post.board == PostBoard.freeBoard,
  CommunityTab.tips => post.board == PostBoard.tips,
};

int _reactions(NeighborPost post) => post.likeCount + post.replyCount;

/// 태그 결과 머리말 — 글 수는 세고, 내 사건과 겹치는 수는 서버가 준다
final tagSummaryProvider = Provider.family<TagSummary, String>((ref, tag) {
  final posts = ref.watch(neighborPostsProvider);
  return TagSummary(
    tag: tag,
    postCount: posts.where((post) => post.tags.contains(tag)).length,
    relatedToMyCase: mockTagRelatedToMyCase[tag] ?? 0,
  );
});

/// 검색 제안 — 태그와 제목을 한 번에 돌려준다
final tagSuggestionsProvider = Provider.family<TagSuggestions, String>((
  ref,
  query,
) {
  final needle = query.replaceAll('#', '').trim().toLowerCase();
  if (needle.isEmpty) return const TagSuggestions();

  final posts = ref.watch(neighborPostsProvider);
  final counts = <String, int>{};
  for (final post in posts) {
    for (final tag in post.tags) {
      if (tag.toLowerCase().contains(needle)) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
  }

  final items =
      [
        for (final entry in counts.entries)
          TagCount(tag: entry.key, postCount: entry.value),
      ]..sort((a, b) {
        final byCount = b.postCount.compareTo(a.postCount);
        return byCount != 0 ? byCount : a.tag.compareTo(b.tag);
      });

  final titles = [
    for (final post in posts)
      if (post.title.toLowerCase().contains(needle))
        TitleSuggestion(
          postId: post.postId,
          title: post.title,
          board: post.board,
          floorBand: post.floorBand,
        ),
  ];

  return TagSuggestions(
    items: items,
    exactMatch: counts.keys.any((tag) => tag.toLowerCase() == '#$needle'),
    titles: titles.take(5).toList(),
  );
});

/// 검색 화면이 비어 있을 때 띄우는 최근 검색어
final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(
      RecentSearchesNotifier.new,
    );

class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => mockRecentSearches;

  void record(String term) => state = [
    term,
    for (final item in state)
      if (item != term) item,
  ].take(8).toList();
}

/// 좋아요 여부와 댓글은 상세 응답에만 있다 — 목록과 따로 들고 있는다
final postInteractionsProvider =
    NotifierProvider<PostInteractionsNotifier, PostInteractions>(
      PostInteractionsNotifier.new,
    );

class PostInteractions {
  final Set<int> likedPostIds;
  final Map<int, List<PostReply>> replies;

  const PostInteractions({required this.likedPostIds, required this.replies});
}

class PostInteractionsNotifier extends Notifier<PostInteractions> {
  @override
  PostInteractions build() => PostInteractions(
    likedPostIds: const {},
    replies: {
      for (final entry in mockPostReplies.entries) entry.key: entry.value,
    },
  );

  void toggleLike(int postId) {
    final liked = state.likedPostIds.contains(postId);
    state = PostInteractions(
      likedPostIds: {
        for (final id in state.likedPostIds)
          if (id != postId) id,
        if (!liked) postId,
      },
      replies: state.replies,
    );
    ref.read(neighborPostsProvider.notifier).bumpLike(postId, liked ? -1 : 1);
  }

  void addReply(int postId, String content) {
    final thread = state.replies[postId] ?? const <PostReply>[];
    state = PostInteractions(
      likedPostIds: state.likedPostIds,
      replies: {
        ...state.replies,
        postId: [
          ...thread,
          PostReply(
            replyId: DateTime.now().millisecondsSinceEpoch,
            nickname: mockMyNickname,
            initials: mockMyInitials,
            floorBand: mockMyFloorBand,
            content: content.trim(),
            createdAt: DateTime.now(),
            isMe: true,
          ),
        ],
      },
    );
    ref.read(neighborPostsProvider.notifier).bumpReply(postId);
  }
}

/// 상세 — 목록의 글에 좋아요 여부와 댓글을 얹는다
final postDetailProvider = FutureProvider.family<PostDetail?, int>((
  ref,
  postId,
) async {
  final posts = ref.watch(neighborPostsProvider);
  final interactions = ref.watch(postInteractionsProvider);

  for (final post in posts) {
    if (post.postId != postId) continue;
    return PostDetail(
      postId: post.postId,
      board: post.board,
      title: post.title,
      content: post.body,
      // 내 글도 작성자 표기는 같다 — 달라지는 건 ⋯ 메뉴뿐이다
      author: PostAuthor(
        label: '${post.floorBand.label} neighbor',
        isMe: post.isMine,
      ),
      tags: post.tags,
      images: [
        if (post.thumbnailUrl != null)
          PostImage(fileId: post.postId, url: post.thumbnailUrl!),
      ],
      likeCount: post.likeCount,
      likedByMe: interactions.likedPostIds.contains(post.postId),
      createdAt: post.createdAt,
      replies: interactions.replies[post.postId] ?? const [],
    );
  }
  return null;
});
