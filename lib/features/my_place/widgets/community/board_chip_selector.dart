import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../models/neighbor_post.dart';

/// 글쓰기 — 어느 게시판에 올릴지
class BoardChipSelector extends StatelessWidget {
  const BoardChipSelector({
    super.key,
    required this.board,
    required this.onSelected,
  });

  final PostBoard board;
  final ValueChanged<PostBoard> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.xs),
      decoration: BoxDecoration(
        color: AppColors.systemPill,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          for (final option in PostBoard.values)
            Expanded(
              child: _Cell(
                label: option == PostBoard.tips ? 'Tips' : 'Free Board',
                selected: option == board,
                onTap: () => onSelected(option),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          alignment: Alignment.center,
          decoration: selected
              ? BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(100),
                )
              : null,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? AppColors.textTitle : AppColors.textSubtle,
              fontSize: 16,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}
