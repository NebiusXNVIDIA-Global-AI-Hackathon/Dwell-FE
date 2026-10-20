import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../models/data_status.dart';
import '../../models/records_insight.dart';
import '../charts/category_bar_list.dart';
import '../charts/threshold_bar.dart';
import '../charts/sparkline_chart.dart';
import 'insights_badge.dart';
import 'insights_card.dart';
import 'link_row.dart';
import 'repeat_badge.dart';

/// Records 탭 — 기록이 적으면 차트를 숨기고 이유를 적는다
class BuildingRecordsCard extends StatelessWidget {
  const BuildingRecordsCard({
    super.key,
    required this.records,
    required this.onHpdHistoryTap,
  });

  final RecordsInsight records;
  final VoidCallback onHpdHistoryTap;

  @override
  Widget build(BuildContext context) {
    final enough = records.status.hasEnoughData;
    final repeated = records.repeatedIssue;

    return InsightsCard(
      title: 'Building records',
      badge: InsightsBadge(
        label: enough ? '${records.periodYears} yrs' : 'Not enough data',
        tone: BadgeTone.neutral,
      ),
      source: records.source,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 18,
        children: [
          Row(
            spacing: Gap.sm,
            children: [
              Expanded(
                child: _BigNumber(
                  value: records.complaints.total,
                  openCount: records.complaints.open,
                  openColor: AppColors.chartWarning,
                  label: 'Complaints',
                ),
              ),
              Expanded(
                child: _BigNumber(
                  value: records.violations.total,
                  openCount: records.violations.open,
                  openColor: AppColors.chartDanger,
                  label: 'Violations',
                ),
              ),
            ],
          ),
          if (enough) ...[
            const _SectionLabel('Complaints by category'),
            CategoryBarList(
              items: {
                for (final entry in records.complaintsByCategory)
                  entry.category: entry.count,
              },
              highlighted: repeated?.category,
            ),
            if (repeated != null)
              RepeatBadge(label: repeated.category, count: repeated.count),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                _SectionLabel(
                  'Complaints per month · ${records.periodYears} yrs',
                ),
                SparklineChart(
                  values: [
                    for (final month in records.complaintsPerMonth) month.count,
                  ],
                  startLabel: _yearOf(records.complaintsPerMonth.first.month),
                  centerLabel: 'per month',
                  endLabel: _yearOf(records.complaintsPerMonth.last.month),
                  height: 42,
                ),
              ],
            ),
          ] else ...[
            ThresholdBar(
              current: records.recordCount,
              total: records.minimumRequired,
              label:
                  '${records.recordCount} of ${records.minimumRequired} records',
              hint: 'Trends need ${records.minimumRequired}+',
            ),
            const Text(
              'Too few records to show categories, repeats or trends.',
              style: TextStyle(
                color: AppColors.textSubtle,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
          LinkRow(label: 'HPD history', onTap: onHpdHistoryTap),
        ],
      ),
    );
  }

  /// `yyyy-MM` 에서 연도만
  String _yearOf(String month) => month.split('-').first;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textSubtle,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _BigNumber extends StatelessWidget {
  const _BigNumber({
    required this.value,
    required this.openCount,
    required this.openColor,
    required this.label,
  });

  final int value;
  final int openCount;
  final Color openColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: 6,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: AppColors.chartInk,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$openCount open',
              style: TextStyle(
                color: openCount == 0 ? AppColors.textMuted : openColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSubtle,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
