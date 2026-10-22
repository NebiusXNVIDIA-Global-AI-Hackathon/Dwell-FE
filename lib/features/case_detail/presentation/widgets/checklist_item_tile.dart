import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme.dart';
import '../../data/case_detail_assets.dart';
import '../../models/checklist_item.dart';
import '../case_detail_tokens.dart';
import 'checklist_card_frame.dart';

class ChecklistItemTile extends StatelessWidget {
  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.editMode,
    required this.editing,
    required this.onToggle,
    required this.onEdit,
    required this.onChanged,
    required this.onDone,
    required this.onDelete,
  });

  final ChecklistItem item;
  final bool editMode;
  final bool editing;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final ValueChanged<String> onChanged;
  final VoidCallback onDone;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final card = ChecklistCardFrame(
      child: Row(
        children: [
          Expanded(
            child: editing
                ? _InlineTextField(
                    initialText: item.text,
                    onChanged: onChanged,
                    onDone: onDone,
                  )
                : Text(
                    item.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CaseDetailText.checklist,
                  ),
          ),
          const SizedBox(width: Gap.sm),
          if (!editing)
            editMode
                ? _EditButton(
                    key: ValueKey('checklist-edit-${item.id}'),
                    onTap: onEdit,
                  )
                : _Toggle(
                    key: ValueKey('checklist-toggle-${item.id}'),
                    done: item.isDone,
                    onTap: onToggle,
                  ),
          const SizedBox(width: CaseDetailSizes.checklistTrailingEnd),
        ],
      ),
    );

    // Swipe to delete checklist item
    return LayoutBuilder(
      builder: (context, constraints) => Slidable(
        key: ValueKey(item.id),
        groupTag: 'case-checklist',
        enabled: !editing,
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: CaseDetailSizes.swipeExtent / constraints.maxWidth,
          children: [
            CustomSlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: CaseDetailColors.swipeDelete,
              foregroundColor: CaseDetailColors.surface,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(CaseDetailSizes.checklistRadius),
              ),
              padding: EdgeInsets.zero,
              child: SvgPicture.asset(
                CaseDetailAssets.trash,
                semanticsLabel: 'Delete item',
              ),
            ),
          ],
        ),
        child: card,
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({super.key, required this.done, required this.onTap});

  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: done,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: CaseDetailSizes.checklistToggle,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: CaseDetailColors.muted,
                    width: CaseDetailSizes.checklistToggleBorder,
                  ),
                ),
              ),
              if (done)
                const Positioned(
                  left: Gap.xs / 2,
                  top: -Gap.xs,
                  child: Icon(
                    LucideIcons.check,
                    size: CaseDetailSizes.checklistIcon,
                    color: CaseDetailColors.navy,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const Icon(
        LucideIcons.squarePen,
        size: CaseDetailSizes.checklistIcon,
        color: CaseDetailColors.muted,
        semanticLabel: 'Edit item',
      ),
    );
  }
}

class _InlineTextField extends StatefulWidget {
  const _InlineTextField({
    required this.initialText,
    required this.onChanged,
    required this.onDone,
  });

  final String initialText;
  final ValueChanged<String> onChanged;
  final VoidCallback onDone;

  @override
  State<_InlineTextField> createState() => _InlineTextFieldState();
}

class _InlineTextFieldState extends State<_InlineTextField> {
  late final _controller = TextEditingController(text: widget.initialText);
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocus);
  }

  // Save when the field loses focus
  void _handleFocus() {
    if (!_focusNode.hasFocus) widget.onDone();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocus);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: true,
      maxLines: 1,
      cursorColor: CaseDetailColors.body,
      textInputAction: TextInputAction.done,
      style: CaseDetailText.checklist,
      decoration: const InputDecoration.collapsed(hintText: null),
      onChanged: widget.onChanged,
      onSubmitted: (_) => _focusNode.unfocus(),
      onTapOutside: (_) => _focusNode.unfocus(),
    );
  }
}
