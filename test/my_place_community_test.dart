import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dwell/core/theme.dart';
import 'package:dwell/features/my_place/models/community_query.dart';
import 'package:dwell/features/my_place/models/neighbor_post.dart';
import 'package:dwell/features/my_place/models/post_draft.dart';
import 'package:dwell/features/my_place/pages/community_search_page.dart';
import 'package:dwell/features/my_place/pages/neighbor_community_page.dart';
import 'package:dwell/features/my_place/pages/post_detail_page.dart';
import 'package:dwell/features/my_place/pages/post_editor_page.dart';
import 'package:dwell/features/my_place/providers/my_place_providers.dart';
import 'package:dwell/features/my_place/widgets/community/neighbor_post_card.dart';
import 'package:dwell/features/my_place/widgets/community/post_menu_button.dart';

Future<void> pumpPage(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(theme: buildTheme(Brightness.light), home: page),
    ),
  );
  await tester.pumpAndSettle();
}

ProviderContainer container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('Tips tab leaves out free board posts', () async {
    final ref = container();

    final tips = await ref.read(
      communityPostsProvider(
        const CommunityQuery(tab: CommunityTab.tips, size: 50),
      ).future,
    );

    expect(tips.content, isNotEmpty);
    expect(tips.content.every((post) => post.board == PostBoard.tips), isTrue);
  });

  test('a new post lands on top of its own board', () async {
    final ref = container();

    ref
        .read(neighborPostsProvider.notifier)
        .submit(
          const PostDraft(
            board: PostBoard.freeBoard,
            title: 'Pipe burst in my unit',
            content: 'Water is coming out from under the kitchen sink.',
            tags: ['#pipeburst'],
          ),
        );

    final page = await ref.read(
      communityPostsProvider(const CommunityQuery(tab: CommunityTab.freeBoard))
          .future,
    );

    expect(page.content.first.title, 'Pipe burst in my unit');
    expect(page.content.first.isMine, isTrue);
  });

  test('liking twice leaves the count where it started', () async {
    final ref = container();
    final before = (await ref.read(postDetailProvider(2).future))!.likeCount;

    ref.read(postInteractionsProvider.notifier).toggleLike(2);
    final liked = (await ref.read(postDetailProvider(2).future))!;
    expect(liked.likedByMe, isTrue);
    expect(liked.likeCount, before + 1);

    ref.read(postInteractionsProvider.notifier).toggleLike(2);
    final undone = (await ref.read(postDetailProvider(2).future))!;
    expect(undone.likedByMe, isFalse);
    expect(undone.likeCount, before);
  });

  test('a reply shows up in the thread and in the list count', () async {
    final ref = container();
    final before = (await ref.read(postDetailProvider(2).future))!;

    ref
        .read(postInteractionsProvider.notifier)
        .addReply(2, 'Mine is on the same line.');

    final after = (await ref.read(postDetailProvider(2).future))!;
    expect(after.replies.length, before.replies.length + 1);
    expect(after.replies.last.content, 'Mine is on the same line.');

    final listed = ref
        .read(neighborPostsProvider)
        .firstWhere((post) => post.postId == 2);
    expect(listed.replyCount, before.replies.length + 1);
  });

  testWidgets('typing a tag brings up matching tags and titles', (
    tester,
  ) async {
    await pumpPage(tester, const CommunitySearchPage());

    await tester.enterText(find.byType(TextField), '#ceil');
    await tester.pumpAndSettle();

    expect(find.text('Tags'), findsOneWidget);
    expect(find.text('#ceilingleak'), findsOneWidget);
    expect(find.text('Titles'), findsOneWidget);
  });

  testWidgets('only my own post offers the edit menu', (tester) async {
    await pumpPage(tester, const PostDetailPage(postId: 2));
    expect(find.byType(PostMenuButton), findsOneWidget);

    await pumpPage(tester, const PostDetailPage(postId: 1));
    expect(find.byType(PostMenuButton), findsNothing);
  });

  testWidgets('space confirms a tag and a leftover one still goes up', (
    tester,
  ) async {
    late ProviderContainer ref;
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // 글쓰기는 밀어서 열리는 화면이다 — Post 를 누르면 닫힌다
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
        GoRoute(path: '/new', builder: (_, _) => const PostEditorPage()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, widgetRef, child) {
            ref = ProviderScope.containerOf(context);
            return MaterialApp.router(
              theme: buildTheme(Brightness.light),
              routerConfig: router,
            );
          },
        ),
      ),
    );
    router.push('/new');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Pipe burst');
    await tester.enterText(find.byType(TextField).at(1), 'Water everywhere');
    // 스페이스바로 하나 확정하고, 하나는 입력칸에 남겨 둔다
    await tester.enterText(find.byType(TextField).at(2), '#pipeburst ');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(2), '#kitchen');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    final post = ref
        .read(neighborPostsProvider)
        .firstWhere((item) => item.title == 'Pipe burst');
    expect(post.tags, ['#pipeburst', '#kitchen']);
  });

  testWidgets('the board tabs swap the listed posts', (tester) async {
    await pumpPage(tester, const NeighborCommunityPage());
    expect(find.byType(NeighborPostCard), findsWidgets);

    // 탭 줄은 가로로 스크롤된다 — 보이게 만든 뒤 누른다
    await tester.scrollUntilVisible(
      find.text('Tips'),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Tips'));
    await tester.pumpAndSettle();

    final cards = tester
        .widgetList<NeighborPostCard>(find.byType(NeighborPostCard))
        .toList();
    expect(cards, isNotEmpty);
    expect(cards.every((card) => card.post.board == PostBoard.tips), isTrue);
  });
}
