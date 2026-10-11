import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 타일 2종의 공통 뼈대 — leading 과 trailing 만 바뀐다
class ChatTile extends StatelessWidget {
  const ChatTile({
    super.key,
    required this.leading,
    required this.title,
    required this.preview,
    required this.timeLabel,
    required this.onTap,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String preview;
  final String timeLabel;
  final VoidCallback onTap;

  /// 미읽음 점 등 시각 아래 요소
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Gap.sm),
        side: const BorderSide(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Gap.card),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Gap.card,
              children: [
                leading,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: Gap.xs,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textTitle,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSubtle,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        color: AppColors.iconGray,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    trailing ?? const SizedBox.shrink(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
