import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_colors.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/state_views.dart';
import '../models/post_detail.dart';
import '../providers/my_place_providers.dart';
import '../widgets/common/my_place_app_bar.dart';
import '../widgets/community/comment_input_bar.dart';
import '../widgets/community/delete_post_dialog.dart';
import '../widgets/community/post_board_badge.dart';
import '../widgets/community/post_menu_button.dart';
import '../widgets/community/post_reply_tile.dart';
import '../widgets/community/post_tag_chip.dart';

/// 게시물 상세 — 본문 · 좋아요 · 댓글
class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({super.key, required this.postId});

  final int postId;

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(postDetailProvider(widget.postId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: detail.when(
          loading: () => const LoadingView(),
          error: (error, _) => AppErrorView(
            error: error,
            onRetry: () => ref.invalidate(postDetailProvider(widget.postId)),
          ),
          data: (data) => data == null
              ? const EmptyView(message: 'This post is no longer here')
              : _Content(
                  detail: data,
                  comment: _comment,
                  onSendComment: () => _sendComment(data.postId),
                  onToggleLike: () => ref
                      .read(postInteractionsProvider.notifier)
                      .toggleLike(data.postId),
                  onEdit: () => context.push(
                    '/my-place/community/post/${data.postId}/edit',
                  ),
                  onDelete: () => _confirmDelete(data.postId),
                ),
        ),
      ),
    );
  }

  void _sendComment(int postId) {
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    ref.read(postInteractionsProvider.notifier).addReply(postId, text);
    _comment.clear();
    setState(() {});
  }

  Future<void> _confirmDelete(int postId) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => DeletePostDialog(
        onDelete: () {
          ref.read(neighborPostsProvider.notifier).remove(postId);
          Navigator.of(dialogContext).pop();
          context.pop();
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.detail,
    required this.comment,
    required this.onSendComment,
    required this.onToggleLike,
    required this.onEdit,
    required this.onDelete,
  });

  final PostDetail detail;
  final TextEditingController comment;
  final VoidCallback onSendComment;
  final VoidCallback onToggleLike;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyPlaceAppBar(
          title: 'Post',
          onBack: () => context.pop(),
          trailing: detail.isMine
              ? PostMenuButton(onEdit: onEdit, onDelete: onDelete)
              : null,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: Gap.md),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Gap.screenH,
                  Gap.card,
                  Gap.screenH,
                  Gap.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PostBoardBadge(board: detail.board),
                    const SizedBox(height: Gap.sm),
                    Text(
                      detail.title,
                      style: const TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: Gap.card),
                    Text(
                      '${detail.author.label} \u00B7 '
                      '${_formatDate(detail.createdAt)}',
                      style: const TextStyle(
                        color: AppColors.iconGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    for (final image in detail.images) ...[
                      const SizedBox(height: Gap.md),
                      _PostImage(image: image),
                    ],
                    const SizedBox(height: Gap.md),
                    Text(
                      detail.content,
                      style: const TextStyle(
                        color: AppColors.textStrong,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: Gap.screenH),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: Gap.sm,
                            runSpacing: Gap.sm,
                            children: [
                              for (final tag in detail.tags)
                                PostTagChip(tag: tag),
                            ],
                          ),
                        ),
                        const SizedBox(width: Gap.sm),
                        _LikeButton(detail: detail, onTap: onToggleLike),
                      ],
                    ),
                    const SizedBox(height: Gap.lg),
                    Text(
                      'Replies (${detail.replies.length})',
                      style: const TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (detail.replies.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: Gap.screenH),
                  child: Text(
                    'No replies yet. Be the first.',
                    style: TextStyle(
                      color: AppColors.textSubtle,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              for (var i = 0; i < detail.replies.length; i++)
                PostReplyTile(
                  reply: detail.replies[i],
                  showDivider: i < detail.replies.length - 1,
                ),
            ],
          ),
        ),
        CommentInputBar(
          controller: comment,
          onSubmit: onSendComment,
          canSubmit: true,
        ),
      ],
    );
  }
}

class _LikeButton extends StatelessWidget {
  const _LikeButton({required this.detail, required this.onTap});

  final PostDetail detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = detail.likedByMe ? AppColors.danger : AppColors.textMuted;

    return Semantics(
      button: true,
      selected: detail.likedByMe,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.xs, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Icon(LucideIcons.heart, size: 18, color: color),
              Text(
                '${detail.likeCount} likes',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 본문 사진 — 서버 URL 이 오기 전까지는 회색 자리
class _PostImage extends StatelessWidget {
  const _PostImage({required this.image});

  final PostImage image;

  @override
  Widget build(BuildContext context) {
    const height = 148.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(Gap.sm),
      child: image.url.startsWith('http')
          ? CachedNetworkImage(
              imageUrl: image.url,
              height: height,
              fit: BoxFit.cover,
              placeholder: (context, _) => const _ImagePlaceholder(),
              errorWidget: (context, _, _) => const _ImagePlaceholder(),
            )
          : const _ImagePlaceholder(),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 148,
    width: double.infinity,
    child: ColoredBox(color: AppColors.infoCard),
  );
}

/// 와프 표기 — `Oct 3rd, 2026`
String _formatDate(DateTime date) =>
    '${DateFormat('MMM').format(date)} ${date.day}${_ordinal(date.day)}, '
    '${date.year}';

String _ordinal(int day) {
  if (day >= 11 && day <= 13) return 'th';
  return switch (day % 10) {
    1 => 'st',
    2 => 'nd',
    3 => 'rd',
    _ => 'th',
  };
}
