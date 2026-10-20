import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// `↻ Water leak ×3` — 반복해서 올라오는 민원
class RepeatBadge extends StatelessWidget {
  const RepeatBadge({super.key, required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: Gap.xs,
        children: [
          const Text(
            '↻',
            style: TextStyle(
              color: AppColors.chartWarning,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$label ×$count',
            style: const TextStyle(
              color: AppColors.chartWarning,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
