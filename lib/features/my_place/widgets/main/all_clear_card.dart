import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import 'rising_issue_card.dart';

/// 올라온 이슈가 없을 때 — 카드 크기는 그대로 유지해 레이아웃이 튀지 않게
class AllClearCard extends StatelessWidget {
  const AllClearCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RisingCardShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: Gap.sm,
        children: [
          Text(
            'All clear!!!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.risingHighlight,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            "We'll let you know if anything comes up",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.surface,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
