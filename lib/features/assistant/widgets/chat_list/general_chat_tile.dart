import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../data/assistant_assets.dart';
import '../../models/chat_thread.dart';
import 'chat_tile.dart';

/// 일반 채팅 타일 — 왼쪽으로 밀어 나가기
class GeneralChatTile extends StatelessWidget {
  const GeneralChatTile({
    super.key,
    required this.thread,
    required this.onTap,
    required this.onLeave,
  });

  final ChatThread thread;
  final VoidCallback onTap;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 빨강 바탕이 타일 뒤에 깔린다 — 밀면 둥근 모서리 뒤로 드러남
        Positioned.fill(
          left: Gap.screenH,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(Gap.sm),
            ),
          ),
        ),
        Slidable(
          key: ValueKey(thread.id),
          groupTag: 'general-chat',
          // 56 / (390 - 20)
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.151,
            children: [
              CustomSlidableAction(
                onPressed: (_) => onLeave(),
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.surface,
                padding: EdgeInsets.zero,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: Gap.xs,
                  children: [
                    Icon(
                      LucideIcons.logOut,
                      size: 24,
                      color: AppColors.surface,
                    ),
                    // 56 폭이라 큰 글씨에서 줄바꿈되지 않게
                    Text(
                      'Leave',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: Gap.screenH),
            child: ChatTile(
              leading: const _DeaverAvatar(),
              title: thread.title,
              preview: thread.preview,
              timeLabel: thread.timeLabel,
              onTap: onTap,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeaverAvatar extends StatelessWidget {
  const _DeaverAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const ShapeDecoration(
        color: AppColors.bubbleAi,
        shape: CircleBorder(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: Image.asset(deaverAvatarPath, width: 40, fit: BoxFit.contain),
      ),
    );
  }
}
