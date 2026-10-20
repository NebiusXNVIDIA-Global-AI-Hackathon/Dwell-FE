import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 탭마다 내용은 달라도 머리와 출처 자리는 같다
class InsightsCard extends StatelessWidget {
  const InsightsCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.badge,
    this.onInfoTap,
    this.source,
  });

  final String title;
  final String? subtitle;
  final Widget? badge;

  /// How we calculate 로 가는 ⓘ — 없으면 아이콘을 숨긴다
  final VoidCallback? onInfoTap;

  /// 카드 맨 아래 출처 문구
  final String? source;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final source = this.source;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(Gap.card),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 18,
        children: [
          _Header(
            title: title,
            subtitle: subtitle,
            badge: badge,
            onInfoTap: onInfoTap,
          ),
          child,
          if (source != null) SourceLabel(text: source),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onInfoTap,
  });

  final String title;
  final String? subtitle;
  final Widget? badge;
  final VoidCallback? onInfoTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final badge = this.badge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Gap.xs,
      children: [
        Row(
          spacing: Gap.sm,
          children: [
            // 제목이 남는 폭을 다 쓰고 배지는 오른쪽 끝에 붙는다
            Expanded(
              child: Row(
                spacing: 6,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.chartInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (onInfoTap != null)
                    Semantics(
                      button: true,
                      label: 'How we calculate',
                      child: InkWell(
                        onTap: onInfoTap,
                        customBorder: const CircleBorder(),
                        child: const Icon(
                          LucideIcons.info,
                          size: 18,
                          color: AppColors.chartNeutral,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ?badge,
          ],
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSubtle,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

/// 데이터 블록 아래 출처 한 줄
class SourceLabel extends StatelessWidget {
  const SourceLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.chartNeutral,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
    );
  }
}
