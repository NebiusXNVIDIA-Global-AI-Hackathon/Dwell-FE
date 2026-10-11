import 'dart:ui' show PointerDeviceKind;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../data/assistant_assets.dart';
import 'new_chat_option_card.dart';

/// 위아래로 끌어 크기를 바꿀 수 있다
class NewChatSheet extends StatelessWidget {
  const NewChatSheet({
    super.key,
    required this.onBlankChat,
    required this.onBringInCase,
  });

  final VoidCallback onBlankChat;
  final VoidCallback onBringInCase;

  static const _sheetHeight = 392.0;

  @override
  Widget build(BuildContext context) {
    // 와프 기준 높이를 화면 비율로 환산 — 작은 화면에서 옵션이 잘리지 않게
    final initial = (_sheetHeight / MediaQuery.sizeOf(context).height).clamp(
      0.3,
      0.95,
    );

    return DraggableScrollableSheet(
      initialChildSize: initial,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          // 웹·데스크톱 기본값은 마우스 드래그를 막는다
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.stylus,
                PointerDeviceKind.invertedStylus,
                PointerDeviceKind.trackpad,
              },
            ),
            child: ListView(
              controller: scrollController,
              // 내용이 짧아도 드래그가 시트로 전달되게
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                const _DragHandle(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.md),
                  child: Text(
                    'Start a new chat',
                    style: TextStyle(
                      color: AppColors.textTitle,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.screenH),
                  child: Column(
                    spacing: Gap.card,
                    children: [
                      NewChatOptionCard(
                        icon: Image.asset(
                          deaverAvatarPath,
                          width: 40,
                          height: 32,
                        ),
                        title: 'Start a blank chat',
                        description:
                            'Ask anything about your home, rights, or a letter '
                            'you got',
                        onTap: onBlankChat,
                      ),
                      NewChatOptionCard(
                        icon: SvgPicture.asset(
                          casesIconPath,
                          width: 28,
                          height: 31,
                        ),
                        title: 'Bring in a case',
                        description:
                            'Load a case you haven’t started yet and choose '
                            'what Deaver can see',
                        onTap: onBringInCase,
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.lg),
                  child: Text(
                    'Cases that already have a chat open from Case chats.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.iconGray, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 68,
        height: 4,
        margin: const EdgeInsets.only(top: Gap.card),
        decoration: const ShapeDecoration(
          color: AppColors.divider,
          shape: StadiumBorder(),
        ),
      ),
    );
  }
}
