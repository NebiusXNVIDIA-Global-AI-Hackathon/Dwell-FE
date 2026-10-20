import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../models/owner_portfolio.dart';
import 'repeat_badge.dart';

/// 같은 소유주 건물 한 채
class OwnerBuildingCard extends StatelessWidget {
  const OwnerBuildingCard({super.key, required this.building});

  final OwnerBuilding building;

  @override
  Widget build(BuildContext context) {
    final mine = building.isThisBuilding;
    final repeatIssue = building.repeatIssue;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: mine ? AppColors.infoText : AppColors.divider,
          width: mine ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(Gap.card),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            spacing: Gap.sm,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Row(
                      spacing: 6,
                      children: [
                        Flexible(
                          child: Text(
                            building.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textTitle,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (mine) const _ThisBuildingPill(),
                      ],
                    ),
                    Text(
                      '${building.units} units · ${building.borough}',
                      style: const TextStyle(
                        color: AppColors.iconGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${building.open}',
                    style: const TextStyle(
                      color: AppColors.chartDanger,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'open',
                    style: TextStyle(
                      color: AppColors.textSubtle,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Row(
              children: [
                Expanded(
                  flex: building.open == 0 ? 0 : building.open,
                  child: Container(height: 6, color: AppColors.chartDanger),
                ),
                Expanded(
                  flex: building.closed == 0 ? 1 : building.closed,
                  child: Container(height: 6, color: AppColors.chartTrack),
                ),
              ],
            ),
          ),
          Row(
            spacing: 6,
            children: [
              _ClassCPill(count: building.classC),
              if (repeatIssue != null)
                RepeatBadge(
                  label: repeatIssue,
                  count: building.repeatCount ?? 0,
                ),
              Expanded(
                child: Text(
                  '${building.closed} closed',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.iconGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThisBuildingPill extends StatelessWidget {
  const _ThisBuildingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: Gap.xs),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Text(
        'This building',
        style: TextStyle(
          color: AppColors.infoText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 가장 심한 등급 — 0건이면 색을 빼서 눈에 띄지 않게
class _ClassCPill extends StatelessWidget {
  const _ClassCPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final open = count > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: Gap.xs),
      decoration: BoxDecoration(
        color: open ? AppColors.dangerSoft : AppColors.chartTrack,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        'Class C · $count',
        style: TextStyle(
          color: open ? AppColors.chartDanger : AppColors.textSubtle,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
