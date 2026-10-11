import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../data/assistant_assets.dart';

/// 채팅 헤더 — 케이스 채팅은 배지, 일반 채팅은 배지 없음
class ChatAppBar extends StatelessWidget {
  const ChatAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onBack,
  });

  final String title;
  final String subtitle;

  /// 케이스 단계 배지 — 일반 채팅은 null
  final String? badge;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Gap.screenH,
            Gap.md,
            Gap.screenH,
            Gap.md,
          ),
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
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSubtle,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null) _StageBadge(label: badge!),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.divider),
      ],
    );
  }
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.card,
        vertical: Gap.xs,
      ),
      decoration: const ShapeDecoration(
        color: AppColors.divider,
        shape: StadiumBorder(),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textBody,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
