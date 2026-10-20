import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 내 글 상세 우상단 — 수정 · 삭제
class PostMenuButton extends StatelessWidget {
  const PostMenuButton({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<bool>(
      tooltip: 'Post options',
      // 와프처럼 ⋯ 바로 아래에서 열린다
      position: PopupMenuPosition.under,
      icon: const Icon(
        LucideIcons.ellipsis,
        size: 24,
        color: AppColors.textTitle,
      ),
      color: AppColors.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.divider),
        borderRadius: BorderRadius.circular(Gap.sm),
      ),
      onSelected: (edit) => edit ? onEdit() : onDelete(),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: true,
          height: 48,
          child: _MenuRow(icon: LucideIcons.squarePen, label: 'Edit'),
        ),
        PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: false,
          height: 48,
          child: _MenuRow(
            icon: LucideIcons.trash2,
            label: 'Delete',
            color: AppColors.danger,
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.color = AppColors.textTitle,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: Gap.card,
      children: [
        Icon(icon, size: 17, color: color),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
