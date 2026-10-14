import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../data/assistant_assets.dart';
import '../../models/info_card.dart';
import 'draft_message_bubble.dart';
import 'info_card_view.dart';

/// Deaver 말풍선 — 카드와 초안은 둘 중 하나만
class DeaverBubble extends StatelessWidget {
  const DeaverBubble({
    super.key,
    required this.text,
    this.card,
    this.draftText,
    this.showAvatar = true,
  });

  final String text;
  final InfoCard? card;
  final String? draftText;

  /// 앞 메시지도 Deaver 면 false
  final bool showAvatar;

  static const _avatarSize = 56.0;
  static const _maxBubbleWidth = 276.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: Gap.screenH, right: Gap.screenH),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.card,
        children: [
          SizedBox(
            width: _avatarSize,
            child: showAvatar ? const _DeaverAvatar() : null,
          ),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxBubbleWidth),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Gap.md,
                  vertical: Gap.card,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bubbleAi,
                  borderRadius: BorderRadius.circular(Gap.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Gap.sm,
                  children: [
                    if (text.isNotEmpty)
                      Text(
                        text,
                        style: const TextStyle(
                          color: AppColors.textStrong,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    if (card != null) InfoCardView(card: card!),
                    if (card?.footnote != null)
                      Text(
                        card!.footnote!,
                        style: const TextStyle(
                          color: AppColors.textStrong,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    if (draftText != null) DraftMessageBubble(text: draftText!),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 아바타 + 아래 이름 라벨
class _DeaverAvatar extends StatelessWidget {
  const _DeaverAvatar();

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: Gap.xs,
      children: [
        Container(
          width: DeaverBubble._avatarSize,
          height: DeaverBubble._avatarSize,
          decoration: const ShapeDecoration(
            color: AppColors.bubbleAi,
            shape: CircleBorder(),
          ),
          clipBehavior: Clip.antiAlias,
          child: Center(
            child: Image.asset(
              deaverAvatarPath,
              width: 40,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const Text(
          'Deaver',
          style: TextStyle(
            color: AppColors.textTitle,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
