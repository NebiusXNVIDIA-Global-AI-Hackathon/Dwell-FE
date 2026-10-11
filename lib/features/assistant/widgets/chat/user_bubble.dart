import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 사용자 말풍선 — 우측 정렬
class UserBubble extends StatelessWidget {
  const UserBubble({super.key, required this.text, this.sentVia});

  final String text;

  /// "Sent via Messages · 3:12 PM"
  final String? sentVia;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: Gap.xs,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 276),
            child: Container(
              padding: const EdgeInsets.all(Gap.md),
              decoration: BoxDecoration(
                color: AppColors.bubbleUser,
                borderRadius: BorderRadius.circular(Gap.card),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (sentVia != null)
            Text(
              sentVia!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
