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
    this.leading,
  });

  final int current;
  final int total;

  /// `1 of 3 fixed violations`
  final String label;

  /// `2 more needed`
  final String hint;

  /// 블록 왼쪽에 서는 그림
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: Gap.md),
      decoration: BoxDecoration(
        color: AppColors.statTile,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        spacing: 14,
        children: [
          ?leading,
          Expanded(
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
                          color: AppColors.chartInk,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
                          color: AppColors.chartNeutral,
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
                                : AppColors.chartTrack,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
