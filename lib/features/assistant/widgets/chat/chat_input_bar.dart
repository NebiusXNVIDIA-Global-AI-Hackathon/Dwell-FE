import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../data/assistant_assets.dart';

/// 입력바 — 자유 입력 없음 · 모양만
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({super.key, this.onAttach});

  final VoidCallback? onAttach;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, Gap.md),
      child: SafeArea(
        top: false,
        child: Row(
          spacing: Gap.md,
          children: [
            Semantics(
              button: true,
              label: 'Add attachment',
              child: InkWell(
                onTap: onAttach,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const ShapeDecoration(
                    color: AppColors.iconGray,
                    shape: CircleBorder(),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      chatAttachIconPath,
                      width: 29,
                      height: 29,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                decoration: const ShapeDecoration(
                  color: AppColors.surface,
                  shape: StadiumBorder(
                    side: BorderSide(color: AppColors.inputBorder),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Send a Message',
                        style: TextStyle(
                          color: AppColors.iconGray,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.48,
                        ),
                      ),
                    ),
                    SvgPicture.asset(chatMicIconPath, width: 15, height: 25),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
