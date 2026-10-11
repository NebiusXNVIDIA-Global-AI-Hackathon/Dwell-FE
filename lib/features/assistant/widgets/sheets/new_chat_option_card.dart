import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// New Chat 옵션 한 칸 — 두 번 재사용
class NewChatOptionCard extends StatelessWidget {
  const NewChatOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final Widget icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Gap.card),
        side: const BorderSide(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Gap.md),
          child: Row(
            spacing: Gap.md,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const ShapeDecoration(
                  color: AppColors.bubbleAi,
                  shape: CircleBorder(),
                ),
                clipBehavior: Clip.antiAlias,
                child: Center(child: icon),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Gap.xs,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSubtle,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
