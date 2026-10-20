import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 시그널 상세 상단 카드 — 완화 표현을 단정형으로 바꾸지 않는다
class DeaverInsightCard extends StatelessWidget {
  const DeaverInsightCard({super.key, required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: AppColors.insightCard,
        borderRadius: BorderRadius.circular(Gap.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.card,
        children: [
          const Text(
            "Deaver's insight",
            style: TextStyle(
              color: AppColors.textTitle,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.insightBody,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
