import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../models/tag_suggestion.dart';

/// 검색 제안 — 태그 한 줄
class TagSuggestionTile extends StatelessWidget {
  const TagSuggestionTile({super.key, required this.item, required this.onTap});

  final TagCount item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SuggestionCard(
      onTap: onTap,
      child: Row(
        spacing: Gap.card,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.systemPill,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '#',
              style: TextStyle(
                color: AppColors.textTitle,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              item.tag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textTitle,
                fontSize: 15,
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
    );
  }
}

/// 검색 제안 — 제목으로 걸린 글
class TitleSuggestionTile extends StatelessWidget {
  const TitleSuggestionTile({
    super.key,
    required this.suggestion,
    required this.onTap,
  });

  final TitleSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SuggestionCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.xs,
        children: [
          Text(
            suggestion.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textTitle,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          Text(
            suggestion.subtitle,
            style: const TextStyle(
              color: AppColors.iconGray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// 최근 검색어 칩 — 누르면 그 태그 결과로 간다
class RecentSearchChip extends StatelessWidget {
  const RecentSearchChip({super.key, required this.tag, required this.onTap});

  final String tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(100),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(100),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: Gap.xs),
          child: Text(
            tag,
            style: const TextStyle(
              color: AppColors.textTitle,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(Gap.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(Gap.sm),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Gap.card,
            vertical: 10,
          ),
          child: child,
        ),
      ),
    );
  }
}
