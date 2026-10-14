import 'package:material_ui/material_ui.dart';

import '../../../../core/theme.dart';
import 'quick_reply_chip.dart';

/// 칩 세로 쌓기 — 버블과 같은 left 정렬
class QuickReplyList extends StatelessWidget {
  const QuickReplyList({super.key, required this.replies, required this.onTap});

  final List<String> replies;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (replies.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(
        left: Gap.screenH + 56 + Gap.card,
        right: Gap.screenH,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.xs,
        children: [
          for (final reply in replies)
            QuickReplyChip(label: reply, onTap: () => onTap(reply)),
        ],
      ),
    );
  }
}
