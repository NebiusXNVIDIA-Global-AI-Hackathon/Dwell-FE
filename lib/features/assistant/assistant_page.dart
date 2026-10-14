import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import '../../core/theme.dart';
import '../../shared/widgets/state_views.dart';
import 'data/chat_list_mock.dart';
import 'models/chat_thread.dart';
import 'providers/chat_providers.dart';
import 'widgets/chat_list/assistant_header.dart';
import 'widgets/chat_list/case_chat_tile.dart';
import 'widgets/chat_list/general_chat_tile.dart';
import 'widgets/chat_list/new_chat_button.dart';
import 'widgets/chat_list/section_title.dart';
import 'widgets/sheets/leave_chat_dialog.dart';
import 'widgets/sheets/new_chat_sheet.dart';

/// Assistant 탭 — 채팅 목록
class AssistantPage extends ConsumerWidget {
  const AssistantPage({super.key});

  void _openChat(BuildContext context, String threadId) {
    context.push('/assistant/chat/$threadId');
  }

  void _confirmLeave(BuildContext context, WidgetRef ref, ChatThread thread) {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (dialogContext) => LeaveChatDialog(
        onLeave: () {
          ref.read(chatThreadsProvider.notifier).remove(thread.id);
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  void _openNewChatSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.scrim,
      isScrollControlled: true,
      // 하단 탭바 위로 띄운다
      useRootNavigator: true,
      // 시트 안 DraggableScrollableSheet 가 세로 제스처를 가져가게
      enableDrag: false,
      builder: (sheetContext) => NewChatSheet(
        // 시트를 먼저 닫지 않으면 시트가 남는다
        onBlankChat: () {
          Navigator.of(sheetContext).pop();
          _openChat(context, newGeneralThreadId);
        },
        onBringInCase: () {
          Navigator.of(sheetContext).pop();
          context.push('/assistant/bring-in-case');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(chatThreadsProvider);
    final caseThreads = [
      for (final thread in threads)
        if (thread.kind == ChatKind.caseChat) thread,
    ];
    final generalThreads = [
      for (final thread in threads)
        if (thread.kind == ChatKind.general) thread,
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              const AssistantHeader(),
              if (threads.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: Gap.xl),
                  child: EmptyView(
                    message: 'Start a chat with Deaver',
                    icon: Icons.chat_bubble_outline,
                  ),
                ),
              if (caseThreads.isNotEmpty) ...[
                const SizedBox(height: Gap.xl),
                const SectionTitle('Case chats'),
                const SizedBox(height: Gap.card),
                for (final thread in caseThreads)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Gap.screenH,
                      0,
                      Gap.screenH,
                      Gap.xs,
                    ),
                    child: CaseChatTile(
                      thread: thread,
                      onTap: () => _openChat(context, thread.id),
                    ),
                  ),
              ],
              if (generalThreads.isNotEmpty) ...[
                const SizedBox(height: Gap.lg),
                const SectionTitle('Other chats'),
                const SizedBox(height: Gap.card),
                for (final thread in generalThreads)
                  Padding(
                    // 왼쪽은 타일 안쪽에서 — 밀 때 내용이 일찍 잘리지 않게
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      0,
                      Gap.screenH,
                      Gap.sm,
                    ),
                    child: GeneralChatTile(
                      thread: thread,
                      onTap: () => _openChat(context, thread.id),
                      onLeave: () => _confirmLeave(context, ref, thread),
                    ),
                  ),
              ],
              // New Chat 버튼에 가리지 않게
              const SizedBox(height: 96),
            ],
          ),
          Positioned(
            right: Gap.screenH,
            bottom: Gap.lg,
            child: NewChatButton(onTap: () => _openNewChatSheet(context)),
          ),
        ],
      ),
    );
  }
}
