import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../models/chat_thread.dart';
import 'chat_tile.dart';

/// 케이스 채팅 타일 — 나가기 없음. 케이스가 살아 있는 동안 유지된다
class CaseChatTile extends StatelessWidget {
  const CaseChatTile({super.key, required this.thread, required this.onTap});

  final ChatThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChatTile(
      leading: const _CaseThumbnail(),
      title: thread.title,
      preview: thread.preview,
      timeLabel: thread.timeLabel,
      onTap: onTap,
      trailing: thread.hasUnread ? const _UnreadDot() : null,
    );
  }
}

/// 증거 사진이 들어올 자리
// TODO: 업로드된 증거 썸네일로 교체 (#17)
class _CaseThumbnail extends StatelessWidget {
  const _CaseThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.infoCard,
        borderRadius: BorderRadius.circular(Gap.sm),
      ),
      child: const Icon(
        Icons.image_outlined,
        size: 20,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 8,
      height: 8,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: AppColors.unreadDot,
          shape: CircleBorder(),
        ),
      ),
    );
  }
}
