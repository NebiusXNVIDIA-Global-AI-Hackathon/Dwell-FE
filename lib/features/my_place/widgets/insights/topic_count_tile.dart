import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../models/neighbor_post.dart';

/// 주제별 글 수 — 숫자와 글자가 항상 함께 간다
class TopicCountTile extends StatelessWidget {
  const TopicCountTile({super.key, required this.topic, required this.count});

  final PostTopic topic;

  /// 데이터가 부족하면 null — 숫자 자리에 줄표
  final int? count;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (topic) {
      PostTopic.slowRepairs => (AppColors.dangerSoft, AppColors.chartDanger),
      PostTopic.noReply => (AppColors.warningSoft, AppColors.warningText),
      PostTopic.fixedWell => (AppColors.successSoft, AppColors.chartSuccess),
    };
    final enough = count != null;

    return Container(
      decoration: BoxDecoration(
        color: enough ? background : AppColors.chartTrack,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Gap.card, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(
            count?.toString() ?? '—',
            style: TextStyle(
              color: enough ? foreground : AppColors.textMuted,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            topic.label,
            maxLines: 2,
            style: TextStyle(
              color: enough ? foreground : AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
