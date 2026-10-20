import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 커뮤니티 목록 우하단 — 글쓰기로 보낸다
class NewPostButton extends StatelessWidget {
  const NewPostButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navy,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        // 큰 글씨에서 넘치지 않게 최소 크기만 고정
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 128, minHeight: 44),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: Gap.xs,
              children: [
                Icon(LucideIcons.plus, size: 24, color: AppColors.bg),
                Text(
                  'New Post',
                  style: TextStyle(
                    color: AppColors.bg,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
