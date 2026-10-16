import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import 'chart_legend.dart';

/// 두 값으로 나뉜 가로바 + 범례 — Owner 탭 위반 비율
class SplitBar extends StatelessWidget {
  const SplitBar({
    super.key,
    required this.ratio,
    required this.fillLabel,
    required this.trackLabel,
    this.fillColor = AppColors.chartDanger,
  });

  /// 0~1. 기록이 없으면 0
  final double ratio;

  /// `Open 39%` 처럼 수치를 포함한 라벨
  final String fillLabel;
  final String trackLabel;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Gap.sm,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Expanded(
                flex: (ratio.clamp(0.0, 1.0) * 1000).round(),
                child: Container(height: 8, color: fillColor),
              ),
              Expanded(
                flex: ((1 - ratio.clamp(0.0, 1.0)) * 1000).round(),
                child: Container(height: 8, color: AppColors.chartTrack),
              ),
            ],
          ),
        ),
        ChartLegend(
          items: [
            ChartLegendItem(label: fillLabel, color: fillColor),
            ChartLegendItem(
              label: trackLabel,
              color: AppColors.textMuted,
              outlined: true,
            ),
          ],
        ),
      ],
    );
  }
}
