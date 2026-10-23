import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme.dart';
import '../../models/case_stage.dart';
import '../case_detail_format.dart';
import '../case_detail_tokens.dart';

/// Bottom sheet that moves the mock case to another stage.
class CaseStageSheet extends StatelessWidget {
  const CaseStageSheet({super.key, required this.current});

  final CaseStage current;

  // Show the stage picker and return the chosen stage
  static Future<CaseStage?> show(BuildContext context, CaseStage current) {
    return showModalBottomSheet<CaseStage>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: CaseDetailColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CaseDetailSizes.sheetRadius),
        ),
      ),
      builder: (_) => CaseStageSheet(current: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.sizeOf(context).height *
            CaseDetailSizes.sheetMaxHeightFactor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              Gap.screenH,
              Gap.lg,
              Gap.screenH,
              Gap.sm,
            ),
            child: Text('Update status', style: CaseDetailText.sectionTitle),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: Gap.md),
              children: [
                for (final stage in CaseStage.values)
                  _StageRow(
                    stage: stage,
                    selected: stage == current,
                    onTap: () => Navigator.of(context).pop(stage),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.stage,
    required this.selected,
    required this.onTap,
  });

  final CaseStage stage;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: CaseDetailSizes.menuItemHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.screenH),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    CaseDetailFormat.stage(stage),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CaseDetailText.checklist.copyWith(
                      color: selected
                          ? CaseDetailColors.navy
                          : CaseDetailColors.body,
                      fontWeight: selected ? FontWeight.w700 : null,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    LucideIcons.check,
                    size: CaseDetailSizes.menuItemIcon,
                    color: CaseDetailColors.navy,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
