import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 일반 채팅 나가기 확인 — 케이스 채팅에는 쓰지 않는다
class LeaveChatDialog extends StatelessWidget {
  const LeaveChatDialog({super.key, required this.onLeave});

  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.all(Gap.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Gap.sm),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 256),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, Gap.card),
              child: Column(
                spacing: Gap.xs,
                children: [
                  Text(
                    'Leave this chat?',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.48,
                    ),
                  ),
                  Text(
                    'Your chat history will be deleted.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textBody,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.48,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _DialogAction(
                      label: 'Cancel',
                      color: AppColors.textBody,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.divider,
                  ),
                  Expanded(
                    child: _DialogAction(
                      label: 'Leave',
                      color: AppColors.link,
                      onTap: onLeave,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Gap.sm),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.36,
            ),
          ),
        ),
      ),
    );
  }
}
