import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 민원 추이 — 축·격자·점 없이 선만. 라벨은 아래 3개
class SparklineChart extends StatelessWidget {
  const SparklineChart({
    super.key,
    required this.values,
    required this.startLabel,
    required this.centerLabel,
    required this.endLabel,
    this.height = 56,
  });

  final List<int> values;
  final String startLabel;
  final String centerLabel;
  final String endLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    var max = 0;
    for (final value in values) {
      if (value > max) max = value;
    }

    return Column(
      spacing: Gap.sm,
      children: [
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: (max == 0 ? 1 : max).toDouble(),
              minX: 0,
              maxX: (values.length - 1).toDouble(),
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: false,
                  barWidth: 2,
                  color: AppColors.chartInk,
                  dotData: const FlDotData(show: false),
                  spots: [
                    for (var i = 0; i < values.length; i++)
                      FlSpot(i.toDouble(), values[i].toDouble()),
                  ],
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            _AxisLabel(text: startLabel),
            Expanded(
              child: Center(child: _AxisLabel(text: centerLabel)),
            ),
            _AxisLabel(text: endLabel),
          ],
        ),
      ],
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
