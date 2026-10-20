import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_colors.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/state_views.dart';
import '../models/building_signal.dart';
import '../providers/my_place_providers.dart';
import '../widgets/common/my_place_app_bar.dart';
import '../widgets/community/deaver_insight_card.dart';
import '../widgets/community/neighbor_post_card.dart';

/// 이슈 하나에 달린 이웃 글 모음
class BuildingSignalsPage extends ConsumerWidget {
  const BuildingSignalsPage({super.key, required this.signalId});

  final int signalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(signalDetailProvider(signalId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: detail.when(
          loading: () => const LoadingView(),
          error: (error, _) => AppErrorView(
            error: error,
            onRetry: () => ref.invalidate(signalDetailProvider(signalId)),
          ),
          data: (signal) => signal == null
              ? const EmptyView(message: 'This signal is no longer available')
              : _Content(signal: signal),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.signal});

  final SignalDetail signal;

  @override
  Widget build(BuildContext context) {
    final insight = signal.insight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyPlaceAppBar(
          title: 'Building Signals - ${signal.title}',
          onBack: () => context.pop(),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, Gap.xl),
            children: [
              if (insight != null) DeaverInsightCard(body: insight.en),
              const SizedBox(height: Gap.lg),
              const Padding(
                padding: EdgeInsets.only(left: Gap.xs, bottom: Gap.card),
                child: Text(
                  'Neighbor reports',
                  style: TextStyle(
                    color: AppColors.textTitle,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (signal.posts.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: Gap.lg),
                  child: EmptyView(message: 'No neighbor reports yet'),
                )
              else
                for (final post in signal.posts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.card),
                    child: NeighborPostCard(
                      post: post,
                      onTap: () => context.push(
                        '/my-place/community/post/${post.postId}',
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
