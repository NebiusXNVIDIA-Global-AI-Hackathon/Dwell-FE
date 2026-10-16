import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 카테고리별 민원 수 — Records 탭
class CategoryBarList extends StatelessWidget {
  const CategoryBarList({super.key, required this.items, this.highlighted});

  final Map<String, int> items;

  /// 반복 카테고리 — 순위와 무관하게 이 항목만 주황
  final String? highlighted;

  @override
  Widget build(BuildContext context) {
    final max = items.values.fold(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Gap.card,
      children: [
        for (final entry in items.entries)
          _CategoryRow(
            label: entry.key,
            value: entry.value,
            ratio: max == 0 ? 0 : entry.value / max,
            isHighlighted: entry.key == highlighted,
          ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.label,
    required this.value,
    required this.ratio,
    required this.isHighlighted,
  });

  final String label;
  final int value;
  final double ratio;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Row(
          spacing: Gap.sm,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$value',
              style: const TextStyle(
                color: AppColors.textTitle,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Row(
            children: [
              Expanded(
                flex: (ratio.clamp(0.0, 1.0) * 1000).round(),
                child: Container(
                  height: 6,
                  color: isHighlighted
                      ? AppColors.chartWarning
                      : AppColors.chartInk,
                ),
              ),
              Expanded(
                flex: ((1 - ratio.clamp(0.0, 1.0)) * 1000).round(),
                child: Container(height: 6, color: AppColors.chartTrack),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
