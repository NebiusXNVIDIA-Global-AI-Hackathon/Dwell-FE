import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../../assistant/data/assistant_assets.dart';

/// 상세 화면 헤더 — 뒤로가기 + 제목 (+ 부제)
class MyPlaceAppBar extends StatelessWidget {
  const MyPlaceAppBar({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onBack;

  /// 우상단 자리 — 내 글 상세의 ⋯ 메뉴
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.screenH, Gap.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.md,
        children: [
          Semantics(
            button: true,
            label: 'Back',
            child: InkWell(
              onTap: onBack,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: SvgPicture.asset(
                    chatBackIconPath,
                    width: 29,
                    height: 29,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Gap.xs,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textTitle,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.iconGray,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
