import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';

/// 내 글 삭제 확인 — 되돌릴 수 없다
class DeletePostDialog extends StatelessWidget {
  const DeletePostDialog({super.key, required this.onDelete});

  final VoidCallback onDelete;

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
                    'Delete this post?',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.48,
                    ),
                  ),
                  Text(
                    'Replies will be removed with it.',
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
                      label: 'Delete',
                      color: AppColors.danger,
                      onTap: onDelete,
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
