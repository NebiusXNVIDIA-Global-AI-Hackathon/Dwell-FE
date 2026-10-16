import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 범례 1칸 — 색만으로 구분되지 않으므로 라벨은 필수
class ChartLegendItem {
  final String label;
  final Color color;

  /// 비어 있는 조각 — 점을 테두리만 그린다
  final bool outlined;

  const ChartLegendItem({
    required this.label,
    required this.color,
    this.outlined = false,
  });
}

/// 차트 아래 · 카드 머리 공용 범례
class ChartLegend extends StatelessWidget {
  const ChartLegend({
    super.key,
    required this.items,
    this.alignment = WrapAlignment.start,
  });

  final List<ChartLegendItem> items;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: alignment,
      spacing: Gap.md,
      runSpacing: Gap.sm,
      children: [for (final item in items) _LegendEntry(item: item)],
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.item});

  final ChartLegendItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        // 빈 조각은 테두리만 — 채우면 Open 과 헷갈린다
        Container(
          width: 8,
          height: 8,
          decoration: ShapeDecoration(
            color: item.outlined ? null : item.color,
            shape: item.outlined
                ? CircleBorder(side: BorderSide(color: item.color, width: 1.5))
                : const CircleBorder(),
          ),
        ),
        Flexible(
          child: Text(
            item.label,
            style: const TextStyle(
              color: AppColors.textBody,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
