import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../data/insights_mock.dart';
import '../../data/my_place_assets.dart';
import '../../models/data_status.dart';
import '../../models/landlord_post_summary.dart';
import '../../models/neighbor_post.dart';
import '../charts/threshold_bar.dart';
import '../community/neighbor_post_card.dart';
import 'insights_badge.dart';
import 'insights_card.dart';
import 'link_row.dart';
import 'topic_count_tile.dart';

/// Tenants 탭 — 집주인을 언급한 이웃 글 집계
class NeighborPostsCard extends StatelessWidget {
  const NeighborPostsCard({
    super.key,
    required this.summary,
    required this.onViewAll,
    required this.onGoToCommunity,
  });

  final LandlordPostSummary summary;
  final VoidCallback onViewAll;

  /// 글이 모자랄 때 커뮤니티로 보내는 버튼
  final VoidCallback onGoToCommunity;

  @override
  Widget build(BuildContext context) {
    final enough = summary.status.hasEnoughData;

    if (!enough) return _lowData(context);

    return InsightsCard(
      title: 'Neighbor posts',
      subtitle: 'What neighbors mention',
      badge: InsightsBadge(
        label: '${summary.postCount} posts',
        tone: BadgeTone.info,
      ),
      source: landlordPostsSource,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.md,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Gap.sm,
              children: [
                for (final topic in PostTopic.values)
                  Expanded(
                    child: TopicCountTile(
                      topic: topic,
                      count: summary.countOf(topic),
                    ),
                  ),
              ],
            ),
          ),
          for (final post in summary.previewPosts)
            NeighborPostCard(post: post, compact: true),
          LinkRow(
            label: 'View all ${summary.postCount} posts in Neighbor Community',
            onTap: onViewAll,
          ),
        ],
      ),
    );
  }

  /// 글이 3개 미만 — 집계 대신 얼마나 더 필요한지 보여준다
  Widget _lowData(BuildContext context) {
    final remaining = summary.minimumRequired - summary.postCount;

    return InsightsCard(
      title: 'Neighbor posts',
      badge: const InsightsBadge(
        label: 'Not enough data',
        tone: BadgeTone.neutral,
      ),
      source:
          'Source: Neighbor Community \u00B7 ${summary.postCount} posts '
          '(${summary.minimumRequired}+ needed)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.md,
        children: [
          ThresholdBar(
            current: summary.postCount,
            total: summary.minimumRequired,
            label: '${summary.postCount} of ${summary.minimumRequired} posts',
            hint: '$remaining more needed',
            leading: Image.asset(
              deaverInspection,
              width: 56,
              fit: BoxFit.contain,
            ),
          ),
          Text(
            'Posts that mention this landlord will show here once '
            '${summary.minimumRequired}+ neighbors share.',
            style: const TextStyle(
              color: AppColors.textSubtle,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onGoToCommunity,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                side: const BorderSide(color: AppColors.chartInk, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Go to Neighbor Community',
                style: TextStyle(
                  color: AppColors.chartInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
