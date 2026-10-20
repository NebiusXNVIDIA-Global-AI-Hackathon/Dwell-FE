import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_colors.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/state_views.dart';
import '../models/community_query.dart';
import '../models/neighbor_post.dart';
import '../providers/my_place_providers.dart';
import '../widgets/common/my_place_app_bar.dart';
import '../widgets/common/my_place_search_field.dart';
import '../widgets/common/underline_tabs.dart';
import '../widgets/community/neighbor_post_card.dart';
import '../widgets/community/new_post_button.dart';

/// 이웃 게시판 — 추천 · 자유게시판 · 팁
class NeighborCommunityPage extends ConsumerStatefulWidget {
  const NeighborCommunityPage({
    super.key,
    this.initialTab = CommunityTab.recommended,
  });

  /// 글을 올린 직후에는 그 게시판 탭으로 돌아온다
  final CommunityTab initialTab;

  @override
  ConsumerState<NeighborCommunityPage> createState() =>
      _NeighborCommunityPageState();
}

class _NeighborCommunityPageState extends ConsumerState<NeighborCommunityPage> {
  late CommunityQuery _query = CommunityQuery(tab: widget.initialTab);

  /// 글을 올리면 그 글이 맨 위에 보이는 탭으로 옮겨 준다
  Future<void> _openEditor() async {
    final board = await context.push<PostBoard>('/my-place/community/new');
    if (board == null || !mounted) return;
    setState(
      () => _query = _query.copyWith(
        tab: board == PostBoard.tips
            ? CommunityTab.tips
            : CommunityTab.freeBoard,
        page: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(communityPostsProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyPlaceAppBar(
                  title: 'Neighbor Community',
                  onBack: () => context.pop(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Gap.screenH,
                    Gap.sm,
                    Gap.screenH,
                    Gap.md,
                  ),
                  child: MyPlaceSearchField(
                    hintText: 'Search title or #tag',
                    onTap: () => context.push('/my-place/community/search'),
                  ),
                ),
                UnderlineTabs(
                  labels: [for (final tab in CommunityTab.values) tab.label],
                  selected: CommunityTab.values.indexOf(_query.tab),
                  fontSize: 16,
                  showBaseline: true,
                  onSelected: (index) => setState(
                    () => _query = _query.copyWith(
                      tab: CommunityTab.values[index],
                      page: 0,
                    ),
                  ),
                ),
                Expanded(
                  child: page.when(
                    loading: () => const LoadingView(),
                    error: (error, _) => AppErrorView(
                      error: error,
                      onRetry: () =>
                          ref.invalidate(communityPostsProvider(_query)),
                    ),
                    data: (data) => data.content.isEmpty
                        ? const EmptyView(message: 'No posts on this board yet')
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              Gap.screenH,
                              Gap.card,
                              Gap.screenH,
                              // New Post 버튼에 카드가 가리지 않게 띄운다
                              88,
                            ),
                            itemCount: data.content.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final post = data.content[index];
                              return NeighborPostCard(
                                post: post,
                                onTap: () => context.push(
                                  '/my-place/community/post/${post.postId}',
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: Gap.screenH,
              bottom: Gap.lg,
              child: NewPostButton(onTap: _openEditor),
            ),
          ],
        ),
      ),
    );
  }
}
