import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';

/// 분기별 민원 · 위반 그룹 막대 — HPD History
/// 범례는 카드 머리에서 따로 그린다
class QuarterlyBarChart extends StatelessWidget {
  const QuarterlyBarChart({
    super.key,
    required this.quarters,
    required this.startYear,
    this.height = 72,
  });

  /// 가장 오래된 분기부터
  final List<({int complaints, int violations})> quarters;
  final int startYear;
  final double height;

  @override
  Widget build(BuildContext context) {
    var max = 1;
    for (final quarter in quarters) {
      if (quarter.complaints > max) max = quarter.complaints;
      if (quarter.violations > max) max = quarter.violations;
    }

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: max.toDouble(),
          groupsSpace: 10,
          alignment: BarChartAlignment.spaceBetween,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
                getTitlesWidget: _yearLabel,
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < quarters.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 2,
                barRods: [
                  _rod(quarters[i].complaints, AppColors.chartInk),
                  _rod(quarters[i].violations, AppColors.chartDanger),
                ],
              ),
          ],
        ),
      ),
    );
  }

  BarChartRodData _rod(int value, Color color) => BarChartRodData(
    toY: value.toDouble(),
    color: color,
    width: 5,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
  );

  /// 연 단위로 한 번만 — 12분기를 전부 쓰지 않는다
  Widget _yearLabel(double value, TitleMeta meta) {
    final index = value.round();
    if (index % 4 != 0) return const SizedBox.shrink();

    final year = (startYear + index ~/ 4) % 100;
    return Text(
      "'$year",
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
