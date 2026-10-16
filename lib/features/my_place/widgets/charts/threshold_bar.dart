import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 점수를 만들기까지 몇 건 남았는지 — 저데이터 카드 전용
class ThresholdBar extends StatelessWidget {
  const ThresholdBar({
    super.key,
    required this.current,
    required this.total,
    required this.label,
    required this.hint,
  });

  final int current;
  final int total;

  /// `1 of 3 fixed violations`
  final String label;

  /// `2 more needed`
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.card),
      decoration: BoxDecoration(
        color: AppColors.chartTrack,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.sm,
        children: [
          Row(
            spacing: Gap.sm,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  style: const TextStyle(
                    color: AppColors.textTitle,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // 큰 글씨에서 라벨과 경쟁한다 — 둘 다 줄어들 수 있게
              Flexible(
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          // 칸 수 = 필요 건수. 채운 칸이 현재 건수
          Row(
            spacing: 2,
            children: [
              for (var i = 0; i < total; i++)
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: i < current
                          ? AppColors.chartInk
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(3),
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
