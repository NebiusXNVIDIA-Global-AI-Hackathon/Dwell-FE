import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 도넛 조각 1개 — 라벨과 수치가 범례에 반드시 함께 나간다
class ClassDonutSection {
  final String label;
  final int total;
  final int open;
  final Color color;

  const ClassDonutSection({
    required this.label,
    required this.total,
    required this.open,
    required this.color,
  });
}

/// 등급별 위반 도넛 + 범례 — HPD History
class ClassDonut extends StatelessWidget {
  const ClassDonut({
    super.key,
    required this.sections,
    required this.centerCaption,
    this.diameter = 96,
    this.thickness = 18,
  });

  final List<ClassDonutSection> sections;

  /// `total`
  final String centerCaption;
  final double diameter;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    var total = 0;
    for (final section in sections) {
      total += section.total;
    }

    return Row(
      spacing: Gap.md,
      children: [
        SizedBox(
          width: diameter,
          height: diameter,
          child: Stack(
            children: [
              Positioned.fill(
                child: PieChart(
                  PieChartData(
                    // 조각 사이를 서피스 색으로 끊는다
                    sectionsSpace: 2,
                    centerSpaceRadius: diameter / 2 - thickness,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(enabled: false),
                    sections: [
                      for (final section in sections)
                        PieChartSectionData(
                          value: section.total.toDouble(),
                          color: section.color,
                          radius: thickness,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      centerCaption,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Gap.sm,
            children: [
              for (final section in sections) _ClassLegendRow(section: section),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClassLegendRow extends StatelessWidget {
  const _ClassLegendRow({required this.section});

  final ClassDonutSection section;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: Gap.sm,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: ShapeDecoration(
            color: section.color,
            shape: const CircleBorder(),
          ),
        ),
        Expanded(
          child: Text(
            section.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textBody,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '${section.total}',
          style: const TextStyle(
            color: AppColors.textTitle,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${section.open} open',
          style: TextStyle(
            // 0건이면 눈에 띌 이유가 없다
            color: section.open == 0 ? AppColors.textMuted : section.color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
