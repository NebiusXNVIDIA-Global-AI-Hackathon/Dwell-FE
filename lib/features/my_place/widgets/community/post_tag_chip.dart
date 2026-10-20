import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// `#ceilingleak` 칩 — 표시 전용
class PostTagChip extends StatelessWidget {
  const PostTagChip({super.key, required this.tag, this.onTap});

  final String tag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: Gap.xs),
      decoration: BoxDecoration(
        color: AppColors.chipSurface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: AppColors.textBody,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: chip,
    );
  }
}
