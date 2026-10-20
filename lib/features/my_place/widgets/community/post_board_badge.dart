import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../models/neighbor_post.dart';

/// 게시판 배지 — Tip 은 노랑, Free Board 는 초록
class PostBoardBadge extends StatelessWidget {
  const PostBoardBadge({super.key, required this.board});

  final PostBoard board;

  @override
  Widget build(BuildContext context) {
    final isTip = board == PostBoard.tips;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: Gap.xs),
      decoration: BoxDecoration(
        color: isTip ? AppColors.boardTipSoft : AppColors.boardFreeSoft,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        isTip ? 'Tip' : 'Free Board',
        style: TextStyle(
          color: isTip ? AppColors.boardTipText : AppColors.boardFreeText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
