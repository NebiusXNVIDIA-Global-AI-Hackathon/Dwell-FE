import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../models/info_card.dart';

/// 버블 안 카드 — 라벨 전종이 이 위젯 하나
class InfoCardView extends StatelessWidget {
  const InfoCardView({super.key, required this.card});

  final InfoCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.card,
        vertical: Gap.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.infoCard,
        borderRadius: BorderRadius.circular(Gap.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.xs,
        children: [
          Text(
            card.label,
            style: const TextStyle(
              color: AppColors.textTitle,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            card.lines.join('\n'),
            style: const TextStyle(
              color: AppColors.cardBody,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          if (card.sourceText != null)
            Text(
              card.sourceText!,
              style: const TextStyle(
                color: AppColors.link,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
