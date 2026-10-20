import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../models/neighbor_post.dart';
import 'post_board_badge.dart';
import 'post_tag_chip.dart';
import 'post_topic_chip.dart';

/// 게시물 카드 — 시그널 상세 · 커뮤니티 · 집주인 언급 글 공용
class NeighborPostCard extends StatelessWidget {
  const NeighborPostCard({
    super.key,
    required this.post,
    this.onTap,
    this.compact = false,
    this.showTopic = false,
    this.showDate = false,
  });

  final NeighborPost post;
  final VoidCallback? onTap;

  /// 요약 자리 — 태그 · 썸네일을 숨기고 좋아요를 머리줄로 올린다
  final bool compact;
  final bool showTopic;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final counts =
        '${post.likeCount} likes · ${post.replyCount} '
        '${post.replyCount == 1 ? 'reply' : 'replies'}';

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
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: Gap.card)
              : const EdgeInsets.all(Gap.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: compact ? 6 : Gap.card,
            children: [
              // 썸네일은 배지줄부터 미리보기까지를 끼고 선다
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Gap.card,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: Gap.sm,
                      children: [
                        Row(
                          spacing: Gap.sm,
                          children: [
                            PostBoardBadge(board: post.board),
                            Expanded(
                              child: Text(
                                post.floorBand.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.iconGray,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (showDate)
                              Text(
                                DateFormat('MMM d').format(post.createdAt),
                                style: const TextStyle(
                                  color: AppColors.iconGray,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (compact) Flexible(child: _Counts(text: counts)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: Gap.xs,
                          children: [
                            Text(
                              post.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.cardBody,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                            Text(
                              post.preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textBody,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!compact && post.thumbnailUrl != null)
                    _Thumbnail(url: post.thumbnailUrl!),
                ],
              ),
              if (!compact)
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: Gap.sm,
                        runSpacing: Gap.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (showTopic && post.landlordTopic != null)
                            PostTopicChip(topic: post.landlordTopic!),
                          for (final tag in post.tags) PostTagChip(tag: tag),
                        ],
                      ),
                    ),
                    const SizedBox(width: Gap.sm),
                    Flexible(child: _Counts(text: counts)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Counts extends StatelessWidget {
  const _Counts({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
      style: const TextStyle(
        color: AppColors.iconGray,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// 사진은 서버가 짧게 유효한 URL 로 준다 — 없는 동안은 빈 회색 자리
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    // 서버 URL 이 아직 없는 목업은 네트워크를 타지 않는다
    if (!url.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Gap.sm),
        child: const _ThumbnailPlaceholder(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(Gap.sm),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 76,
        height: 72,
        fit: BoxFit.cover,
        placeholder: (context, _) => const _ThumbnailPlaceholder(),
        errorWidget: (context, _, _) => const _ThumbnailPlaceholder(),
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 76,
    height: 72,
    child: ColoredBox(color: AppColors.infoCard),
  );
}
