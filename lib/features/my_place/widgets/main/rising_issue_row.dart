import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../data/my_place_assets.dart';
import '../../models/building_signal.dart';

/// 시그널 목록 행
class RisingIssueRow extends StatelessWidget {
  const RisingIssueRow({super.key, required this.signal, required this.onTap});

  final BuildingSignal signal;
  final VoidCallback onTap;

  /// 신고가 이만큼 쌓이면 배지에 색이 붙는다
  static const _attentionReports = 3;

  @override
  Widget build(BuildContext context) {
    final attention = signal.reportCount >= _attentionReports;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(Gap.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(Gap.sm),
          ),
          padding: const EdgeInsets.all(Gap.md),
          child: Row(
            spacing: Gap.card,
            children: [
              SvgPicture.asset(
                issueIconPath(signal.category),
                width: 40,
                height: 40,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Gap.xs,
                  children: [
                    Row(
                      spacing: Gap.sm,
                      children: [
                        Flexible(
                          child: Text(
                            signal.issueLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textTitle,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _ReportBadge(
                          count: signal.reportCount,
                          attention: attention,
                        ),
                      ],
                    ),
                    Text(
                      signal.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textBody,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportBadge extends StatelessWidget {
  const _ReportBadge({required this.count, required this.attention});

  final int count;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: Gap.xs),
      decoration: BoxDecoration(
        color: attention ? AppColors.warningSoft : AppColors.systemPill,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$count reports',
        style: TextStyle(
          color: attention ? AppColors.unreadDot : AppColors.textSubtle,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
