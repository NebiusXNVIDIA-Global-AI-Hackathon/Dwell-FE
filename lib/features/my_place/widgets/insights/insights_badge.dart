import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 카드 머리 상태 알약
enum BadgeTone { danger, warning, success, info, neutral }

class InsightsBadge extends StatelessWidget {
  const InsightsBadge({super.key, required this.label, required this.tone});

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      BadgeTone.danger => (AppColors.dangerSoft, AppColors.chartDanger),
      BadgeTone.warning => (AppColors.warningSoft, AppColors.warningText),
      BadgeTone.success => (AppColors.successSoft, AppColors.chartSuccess),
      BadgeTone.info => (AppColors.infoSoft, AppColors.infoText),
      BadgeTone.neutral => (AppColors.chartTrack, AppColors.textSubtle),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: Gap.xs),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
