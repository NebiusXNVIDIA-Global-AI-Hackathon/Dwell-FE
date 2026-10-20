import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../data/my_place_assets.dart';

/// 상세 하단 고정 — 댓글 입력
class CommentInputBar extends StatelessWidget {
  const CommentInputBar({
    super.key,
    required this.controller,
    required this.onSubmit,
    required this.canSubmit,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool canSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Gap.screenH,
        Gap.sm,
        Gap.screenH,
        Gap.screenH,
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.textMuted),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.only(left: Gap.md, right: Gap.sm),
        child: Row(
          spacing: Gap.sm,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onSubmit(),
                textInputAction: TextInputAction.send,
                style: const TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Leave your comments here...',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Send comment',
              child: InkWell(
                onTap: canSubmit ? onSubmit : null,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(Gap.sm),
                  child: SvgPicture.asset(
                    commentSendIconPath,
                    width: 28,
                    height: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
