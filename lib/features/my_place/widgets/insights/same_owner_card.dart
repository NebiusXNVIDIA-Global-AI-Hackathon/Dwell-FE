import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../models/owner_portfolio.dart';
import '../charts/split_bar.dart';
import 'insights_badge.dart';
import 'insights_card.dart';
import 'link_row.dart';
import 'stat_tile.dart';

/// Owner 탭 — 같은 소유주가 가진 건물 전체의 위반 비율
class SameOwnerCard extends StatelessWidget {
  const SameOwnerCard({
    super.key,
    required this.portfolio,
    required this.onOtherBuildingsTap,
  });

  final OwnerPortfolio portfolio;
  final VoidCallback onOtherBuildingsTap;

  @override
  Widget build(BuildContext context) {
    final enough = portfolio.hasEnoughData;
    final openPercent = (portfolio.openRatio * 100).round();

    return InsightsCard(
      title: 'Same owner',
      badge: enough
          ? null
          : const InsightsBadge(
              label: 'Not enough data',
              tone: BadgeTone.neutral,
            ),
      source: 'Source: HPD building registration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 18,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                Expanded(
                  child: StatTile(
                    value: enough ? '${portfolio.buildingCount}' : '1',
                    label: enough ? 'Buildings' : 'This building',
                    valueSize: 22,
                  ),
                ),
                Expanded(
                  child: StatTile(
                    value: enough ? '${portfolio.open}' : '—',
                    valueColor: enough
                        ? AppColors.chartDanger
                        : AppColors.textMuted,
                    label: 'Open',
                    valueSize: 22,
                  ),
                ),
                Expanded(
                  child: StatTile(
                    value: enough ? '${portfolio.closed}' : '—',
                    valueColor: AppColors.textSubtle,
                    label: 'Closed',
                    valueSize: 22,
                  ),
                ),
              ],
            ),
          ),
          if (enough) ...[
            Text(
              'Violations across all ${portfolio.buildingCount} buildings',
              style: const TextStyle(
                color: AppColors.textSubtle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            SplitBar(
              ratio: portfolio.openRatio,
              fillLabel: 'Open $openPercent%',
              trackLabel: 'Closed ${100 - openPercent}%',
            ),
            LinkRow(label: 'Other buildings', onTap: onOtherBuildingsTap),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.statTile,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Text(
                    'No other buildings found',
                    style: TextStyle(
                      color: AppColors.chartInk,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'HPD registration lists only this building for this owner.',
                    style: TextStyle(
                      color: AppColors.textSubtle,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
