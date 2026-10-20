import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../models/building_signal.dart';

/// 헤더 위에 떠 있는 이슈 카드
class RisingIssueCard extends StatelessWidget {
  const RisingIssueCard({
    super.key,
    required this.signal,
    required this.onCheckUnit,
    this.compact = false,
  });

  final BuildingSignal signal;
  final VoidCallback onCheckUnit;

  /// 캐러셀 안에서는 폭이 좁고 버튼이 글자만큼만 넓다
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return RisingCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.xs,
        children: [
          // 와프는 강조 문구와 제목을 붙여 쓴다
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rising Issue!!!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.risingHighlight,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                compact ? signal.issueLabel : signal.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.surface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${signal.reportCount} ',
                  style: const TextStyle(
                    color: AppColors.risingHighlight,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                  text: 'Reports',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.xs),
          _CheckUnitButton(onTap: onCheckUnit, expand: !compact),
        ],
      ),
    );
  }
}

/// 이슈 카드 · All clear 카드 공용 외형
class RisingCardShell extends StatelessWidget {
  const RisingCardShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 168),
      padding: const EdgeInsets.all(Gap.screenH),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Gap.screenH),
        border: Border.all(
          color: AppColors.surface.withValues(alpha: 0.3),
          width: 2,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.navy.withValues(alpha: 0.6),
            AppColors.risingAction.withValues(alpha: 0.36),
          ],
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 10,
            color: AppColors.navy.withValues(alpha: 0.2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CheckUnitButton extends StatelessWidget {
  const _CheckUnitButton({required this.onTap, required this.expand});

  final VoidCallback onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppColors.risingAction,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: Gap.md),
          alignment: Alignment.center,
          child: const Text(
            'Check my unit',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.surface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
