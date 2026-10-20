import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../models/neighbor_post.dart';

/// 집주인 언급 글의 분류 칩 — 색만으로 구분되지 않으므로 글자를 함께 둔다
class PostTopicChip extends StatelessWidget {
  const PostTopicChip({super.key, required this.topic});

  final PostTopic topic;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (topic) {
      PostTopic.slowRepairs => (AppColors.dangerSoft, AppColors.chartDanger),
      PostTopic.noReply => (AppColors.warningSoft, AppColors.warningText),
      PostTopic.fixedWell => (AppColors.successSoft, AppColors.chartSuccess),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: Gap.xs),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        topic.label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
