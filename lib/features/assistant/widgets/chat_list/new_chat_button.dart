import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

class NewChatButton extends StatelessWidget {
  const NewChatButton({super.key, required this.onTap});

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
          constraints: const BoxConstraints(minWidth: 136, minHeight: 44),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: Gap.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: Gap.sm,
              children: [
                Icon(LucideIcons.plus, size: 20, color: AppColors.surface),
                Text(
                  'New Chat',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 15,
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
