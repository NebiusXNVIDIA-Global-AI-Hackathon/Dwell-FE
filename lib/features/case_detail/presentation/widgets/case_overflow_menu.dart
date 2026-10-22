import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme.dart';
import '../case_detail_tokens.dart';

enum _CaseMenuAction { addEvidence, delete }

class CaseOverflowMenu extends StatelessWidget {
  const CaseOverflowMenu({
    super.key,
    required this.onAddEvidence,
    required this.onDelete,
  });

  final VoidCallback onAddEvidence;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // Pressed rows get the Figma gray highlight instead of a ripple
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: CaseDetailColors.divider,
        splashFactory: NoSplash.splashFactory,
      ),
      child: PopupMenuButton<_CaseMenuAction>(
        tooltip: 'Case options',
        position: PopupMenuPosition.under,
        offset: const Offset(-Gap.xs, 0),
        padding: EdgeInsets.zero,
        menuPadding: EdgeInsets.zero,
        color: CaseDetailColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: Gap.xs,
        shadowColor: CaseDetailColors.floatShadow,
        constraints: const BoxConstraints.tightFor(
          width: CaseDetailSizes.menuWidth,
        ),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: CaseDetailColors.divider),
          borderRadius: BorderRadius.circular(CaseDetailSizes.menuRadius),
        ),
        onSelected: (action) => switch (action) {
          _CaseMenuAction.addEvidence => onAddEvidence(),
          _CaseMenuAction.delete => onDelete(),
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: _CaseMenuAction.addEvidence,
            height: CaseDetailSizes.menuItemHeight,
            padding: EdgeInsets.zero,
            child: _MenuRow(
              icon: LucideIcons.plus,
              label: 'Add Evidence',
              color: CaseDetailColors.navy,
              divider: true,
            ),
          ),
          PopupMenuItem(
            value: _CaseMenuAction.delete,
            height: CaseDetailSizes.menuItemHeight,
            padding: EdgeInsets.zero,
            child: _MenuRow(
              icon: LucideIcons.trash2,
              label: 'Delete',
              color: CaseDetailColors.destructive,
            ),
          ),
        ],
        child: const SizedBox.square(
          dimension: CaseDetailSizes.menuButton,
          child: Icon(
            LucideIcons.ellipsis,
            size: CaseDetailSizes.menuIcon,
            color: CaseDetailColors.navy,
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.color,
    this.divider = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: CaseDetailSizes.menuItemHeight,
      padding: const EdgeInsets.symmetric(horizontal: Gap.md),
      decoration: divider
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: CaseDetailColors.divider),
              ),
            )
          : null,
      child: Row(
        spacing: Gap.card,
        children: [
          Icon(icon, size: CaseDetailSizes.menuItemIcon, color: color),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaseDetailText.menuItem.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
