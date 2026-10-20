import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 결과 다이얼로그에서 고른 다음 행동
enum InspectionChoice { talkToDeaver, createCase }

/// 체크 결과 — 상담으로 갈지 케이스를 만들지 고른다
class InspectionResultDialog extends StatelessWidget {
  const InspectionResultDialog({super.key});

  static Future<InspectionChoice?> show(BuildContext context) {
    return showDialog<InspectionChoice>(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (context) => const InspectionResultDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.all(Gap.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Gap.card),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.lg,
                Gap.lg,
                Gap.lg,
                Gap.lg,
              ),
              child: Column(
                spacing: Gap.card,
                children: const [
                  Text(
                    'Your unit might be affected',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.cardBody,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  Text(
                    'Create a case now or talk to Deaver first?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textBody,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _DialogAction(
                      label: 'Talk to Deaver',
                      color: AppColors.textBody,
                      onTap: () =>
                          Navigator.of(context)
                              .pop(InspectionChoice.talkToDeaver),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: AppColors.divider),
                  Expanded(
                    child: _DialogAction(
                      label: 'Create Case',
                      color: AppColors.link,
                      onTap: () =>
                          Navigator.of(context)
                              .pop(InspectionChoice.createCase),
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

class _DialogAction extends StatelessWidget {
  const _DialogAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
