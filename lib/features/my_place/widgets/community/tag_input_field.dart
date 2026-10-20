import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../models/tag_suggestion.dart';

/// 글쓰기 — 고른 태그 칩과 입력칸이 한 상자 안에 있다
class TagInputField extends StatelessWidget {
  const TagInputField({
    super.key,
    required this.tags,
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.onSubmitted,
    required this.onRemove,
    required this.onChanged,
  });

  final List<String> tags;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: focused ? AppColors.navy : AppColors.divider,
          width: focused ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(Gap.sm),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final tag in tags)
            _SelectedTagChip(tag: tag, onRemove: () => onRemove(tag)),
          // 칩 두 개 옆에 그대로 붙는 폭 — 더 넓으면 줄이 꺾인다
          SizedBox(
            width: 96,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.done,
              style: const TextStyle(
                color: AppColors.textTitle,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '#tag',
                hintStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedTagChip extends StatelessWidget {
  const _SelectedTagChip({required this.tag, required this.onRemove});

  final String tag;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.tagSelected,
        borderRadius: BorderRadius.circular(100),
      ),
      padding: const EdgeInsets.fromLTRB(10, Gap.xs, Gap.sm, Gap.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Text(
            tag,
            style: const TextStyle(
              color: AppColors.link,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Semantics(
            button: true,
            label: 'Remove $tag',
            child: GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: const Text(
                '×',
                style: TextStyle(
                  color: AppColors.link,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 입력칸 아래 제안 — 이미 있는 태그를 고르거나 새로 만든다
class TagSuggestionPanel extends StatelessWidget {
  const TagSuggestionPanel({
    super.key,
    required this.suggestions,
    required this.typed,
    required this.onPick,
    required this.onCreate,
  });

  final TagSuggestions suggestions;

  /// `#` 를 붙인 입력값
  final String typed;
  final ValueChanged<String> onPick;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final canCreate = typed.length > 1 && !suggestions.exactMatch;
    if (suggestions.items.isEmpty && !canCreate) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(Gap.sm),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 6),
            blurRadius: 8,
            color: Color(0x1F000000),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final item in suggestions.items.take(3))
            _PanelRow(
              onTap: () => onPick(item.tag),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${item.postCount} posts',
                    style: const TextStyle(
                      color: AppColors.iconGray,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          if (canCreate)
            _PanelRow(
              last: true,
              onTap: onCreate,
              child: Text(
                '+  Create new tag “$typed”',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.link,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PanelRow extends StatelessWidget {
  const _PanelRow({
    required this.child,
    required this.onTap,
    this.last = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: Gap.md),
        child: child,
      ),
    );
  }
}
