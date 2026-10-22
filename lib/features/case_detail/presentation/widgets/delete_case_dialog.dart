import 'package:material_ui/material_ui.dart';

import '../../../../core/theme.dart';
import '../case_detail_tokens.dart';

class DeleteCaseDialog extends StatelessWidget {
  const DeleteCaseDialog({super.key});

  // Show delete confirmation dialog
  static Future<bool> show(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: CaseDetailColors.dim,
      builder: (_) => const DeleteCaseDialog(),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CaseDetailColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: CaseDetailSizes.dialogInset,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CaseDetailSizes.dialogRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: CaseDetailSizes.dialogWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                Gap.screenH,
                Gap.screenH,
                Gap.screenH,
                Gap.card,
              ),
              child: Column(
                spacing: Gap.xs,
                children: [
                  Text(
                    'Delete this case?',
                    textAlign: TextAlign.center,
                    style: CaseDetailText.dialogTitle,
                  ),
                  Text(
                    "Everything tied to this case will be permanently deleted, and this can't be undone.",
                    textAlign: TextAlign.center,
                    style: CaseDetailText.dialogBody,
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: CaseDetailColors.divider,
            ),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _DialogAction(
                      label: 'Yes, Delete this case',
                      color: CaseDetailColors.destructive,
                      onTap: () => Navigator.of(context).pop(true),
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: CaseDetailColors.divider,
                  ),
                  Expanded(
                    child: _DialogAction(
                      label: 'Cancel',
                      color: Colors.black,
                      onTap: () => Navigator.of(context).pop(false),
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
      child: SizedBox(
        height: CaseDetailSizes.dialogActionHeight,
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CaseDetailText.dialogAction.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}
