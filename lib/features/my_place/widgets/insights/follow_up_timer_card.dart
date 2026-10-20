import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../models/landlord_insight.dart';

/// 재통지 대기 시간 — Assistant 가 같은 값을 문구로 쓴다
class FollowUpTimerCard extends StatelessWidget {
  const FollowUpTimerCard({super.key, required this.timer});

  final FollowUpTimer timer;

  @override
  Widget build(BuildContext context) {
    final shortened = timer.isShortened;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(Gap.card),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 14),
      child: Row(
        spacing: Gap.card,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.warningSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.clock,
              size: 18,
              color: AppColors.chartWarning,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                const Text(
                  'Follow-up timer',
                  style: TextStyle(
                    color: AppColors.chartInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  timer.reason.label,
                  style: const TextStyle(
                    color: AppColors.chartNeutral,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 6,
            children: [
              // 단축됐을 때만 기본값에 줄을 긋는다
              if (shortened)
                Text(
                  '${timer.defaultHours}h',
                  style: const TextStyle(
                    color: AppColors.chartNeutral,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                '${timer.appliedHours}h',
                style: TextStyle(
                  color: shortened
                      ? AppColors.chartWarning
                      : AppColors.chartInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
