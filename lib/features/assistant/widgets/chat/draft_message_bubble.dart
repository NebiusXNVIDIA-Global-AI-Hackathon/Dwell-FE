import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// Deaver 버블 안 흰 카드 — 통지문 · 답장 초안
class DraftMessageBubble extends StatelessWidget {
  const DraftMessageBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
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
    );
  }
}
