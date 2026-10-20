import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../models/landlord_insight.dart';
import '../charts/chart_legend.dart';
import '../charts/gauge_chart.dart';
import '../charts/mini_donut.dart';
import '../charts/threshold_bar.dart';
import 'insights_badge.dart';
import 'insights_card.dart';
import 'stat_tile.dart';

/// Landlord 탭 본체 — 기록이 부족하면 점수를 비우고 남은 건수를 보여준다
class LandlordTrackRecordCard extends StatelessWidget {
  const LandlordTrackRecordCard({
    super.key,
    required this.record,
    required this.onInfoTap,
  });

  final TrackRecord record;
  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    final enough = record.hasEnoughData;
    final fillColor = record.isSlowerThanCity
        ? AppColors.chartDanger
        : AppColors.chartSuccess;

    return InsightsCard(
      title: 'Landlord track record',
      onInfoTap: onInfoTap,
      badge: InsightsBadge(label: record.rating.label, tone: _tone),
      source: record.source,
      child: Column(
        spacing: 18,
        children: [
          GaugeChart(
            value: record.avgDaysToFix,
            maxValue: record.gaugeMaxDays,
            caption: 'avg. days to fix',
            startLabel: '0',
            endLabel: '${record.gaugeMaxDays}d',
            markerValue: enough ? record.nycAvgDaysToFix : null,
            markerLabel: 'NYC ${record.nycAvgDaysToFix}d',
            fillColor: fillColor,
          ),
          if (enough)
            ChartLegend(
              alignment: WrapAlignment.center,
              items: [
                ChartLegendItem(
                  label: 'This building ${record.avgDaysToFix}d',
                  color: fillColor,
                ),
                ChartLegendItem(
                  label: 'NYC avg. ${record.nycAvgDaysToFix}d',
                  color: AppColors.chartInk,
                ),
              ],
            )
          else
            ThresholdBar(
              current: record.fixedViolations,
              total: record.minimumRequired,
              label:
                  '${record.fixedViolations} of ${record.minimumRequired} '
                  'fixed violations',
              hint: '${record.remainingForScore} more needed',
            ),
          // stretch 는 높이가 정해진 뒤에만 성립한다
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                Expanded(
                  child: StatTile(
                    leading: MiniDonut(
                      ratio: record.violations.openRatio,
                      color: AppColors.chartDanger,
                      thickness: 6,
                    ),
                    value:
                        '${record.violations.open} / '
                        '${record.violations.total} open',
                    label: 'Violations',
                  ),
                ),
                Expanded(
                  child: StatTile(
                    leading: LetterMark(
                      letter: 'C',
                      background: record.classC.open > 0
                          ? AppColors.dangerSoft
                          : AppColors.chartTrack,
                      foreground: record.classC.open > 0
                          ? AppColors.chartDanger
                          : AppColors.textSubtle,
                    ),
                    value: '${record.classC.open} open',
                    valueColor: record.classC.open > 0
                        ? AppColors.chartDanger
                        : AppColors.textMuted,
                    label: 'Class C',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BadgeTone get _tone => switch (record.rating) {
    LandlordRating.slowToFix => BadgeTone.danger,
    LandlordRating.fixesQuickly => BadgeTone.success,
    LandlordRating.aboutAverage => BadgeTone.info,
    LandlordRating.notEnoughData => BadgeTone.neutral,
  };
}
