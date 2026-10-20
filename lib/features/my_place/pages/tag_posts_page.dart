import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_colors.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/state_views.dart';
import '../models/community_query.dart';
import '../providers/my_place_providers.dart';
import '../widgets/common/my_place_app_bar.dart';
import '../widgets/community/neighbor_post_card.dart';

/// 태그 하나로 추린 글 — 검색 제안에서 들어온다
class TagPostsPage extends ConsumerWidget {
  const TagPostsPage({super.key, required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(tagSummaryProvider(tag));
    final page = ref.watch(
      communityPostsProvider(CommunityQuery(tag: tag, size: 50)),
    );

    final counts = [
      '${summary.postCount} ${summary.postCount == 1 ? 'post' : 'posts'}',
      if (summary.relatedToMyCase > 0)
        '${summary.relatedToMyCase} related to your case',
    ].join(' · ');

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyPlaceAppBar(
              title: tag,
              subtitle: counts,
              onBack: () => context.pop(),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(Gap.screenH, Gap.card, 0, 0),
              child: Text(
                'Recent',
                style: TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
            Expanded(
              child: page.when(
                loading: () => const LoadingView(),
                error: (error, _) => AppErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(communityPostsProvider),
                ),
                data: (data) => data.content.isEmpty
                    ? EmptyView(message: 'No posts tagged $tag yet')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          Gap.screenH,
                          Gap.card,
                          Gap.screenH,
                          Gap.xl,
                        ),
                        itemCount: data.content.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: Gap.sm),
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
      ),
    );
  }
}
