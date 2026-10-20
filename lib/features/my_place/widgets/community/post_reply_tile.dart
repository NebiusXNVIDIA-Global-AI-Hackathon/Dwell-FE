import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../models/post_detail.dart';

/// 댓글 한 줄 — 이니셜 원 + 닉네임·층 + 본문
class PostReplyTile extends StatelessWidget {
  const PostReplyTile({
    super.key,
    required this.reply,
    this.showDivider = true,
  });

  final PostReply reply;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.divider))
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.card, Gap.screenH, Gap.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.lg,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.divider,
              shape: BoxShape.circle,
            ),
            child: Text(
              reply.initials,
              style: const TextStyle(
                color: AppColors.textTitle,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Gap.sm,
              children: [
                Text(
                  reply.authorLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textTitle,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                Text(
                  reply.content,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
