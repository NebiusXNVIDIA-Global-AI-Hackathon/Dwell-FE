import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 가운데 pill — 시각 구분 · 상태 전이 알림
class SystemNotice extends StatelessWidget {
  const SystemNotice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.card,
          vertical: Gap.xs,
        ),
        decoration: const ShapeDecoration(
          color: AppColors.systemPill,
          shape: StadiumBorder(),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textBody,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
