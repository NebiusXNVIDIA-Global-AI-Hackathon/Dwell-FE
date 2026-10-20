import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../models/open_closed_count.dart';

/// 민원 · 위반 합계와 진행 비율
class HpdSummaryTile extends StatelessWidget {
  const HpdSummaryTile({
    super.key,
    required this.count,
    required this.label,
    required this.openColor,
  });

  final OpenClosedCount count;
  final String label;
  final Color openColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.statTile,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(Gap.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.sm,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 6,
            children: [
              Text(
                '${count.total}',
                style: const TextStyle(
                  color: AppColors.chartInk,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSubtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Row(
              children: [
                Expanded(
                  flex: count.open == 0 ? 0 : count.open,
                  child: Container(height: 6, color: openColor),
                ),
                Expanded(
                  flex: count.closed == 0 ? 1 : count.closed,
                  child: Container(height: 6, color: AppColors.chartTrack),
                ),
              ],
            ),
          ),
          Text(
            '${count.open} open · ${count.closed} closed',
            style: const TextStyle(
              color: AppColors.textSubtle,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
