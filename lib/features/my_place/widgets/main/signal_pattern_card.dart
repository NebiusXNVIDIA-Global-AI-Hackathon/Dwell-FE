import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../data/my_place_assets.dart';
import '../../models/building_signal.dart';

/// 시그널 목록 맨 위 — 내 케이스와 겹치는 패턴 요약
class SignalPatternCard extends StatelessWidget {
  const SignalPatternCard({
    super.key,
    required this.signal,
    required this.onViewDetails,
  });

  final PrimarySignal signal;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Gap.sm),
      child: ColoredBox(
        color: AppColors.insightCard,
        child: Stack(
          children: [
            // 일러스트는 카드 왼쪽 밖으로 걸쳐 나간다
            Positioned(
              left: -36,
              top: 48,
              width: 192,
              height: 224,
              child: Image.asset(
                signalPatternIllustration,
                fit: BoxFit.contain,
                alignment: Alignment.topLeft,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.md,
                Gap.lg,
                Gap.md,
                Gap.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Gap.lg,
                children: [
                  Center(
                    child: Text(
                      '${signal.issueLabel} pattern detected',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Padding(
                    // 일러스트가 차지하는 왼쪽을 비워 둔다
                    padding: const EdgeInsets.only(left: 148),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: Gap.md,
                      children: [
                        _PatternLine(
                          label: signal.issueLabel,
                          value: '${signal.reportCount} cases reported',
                        ),
                        if (signal.reportedIn.isNotEmpty)
                          _PatternLine(
                            label: 'Reported In',
                            value: signal.reportedIn.join(', '),
                          ),
                        _PatternLine(
                          label: 'In the Last',
                          value: signal.windowLabel,
                        ),
                        _ViewDetailsButton(onTap: onViewDetails),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternLine extends StatelessWidget {
  const _PatternLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Gap.card,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: SizedBox(
            width: 8,
            height: 8,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: AppColors.chartSuccess,
                shape: CircleBorder(),
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textBody,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ViewDetailsButton extends StatelessWidget {
  const _ViewDetailsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navy,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: Gap.md),
          alignment: Alignment.center,
          child: const Text(
            'View Issue Details  →',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.surface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
