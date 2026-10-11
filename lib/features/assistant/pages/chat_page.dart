import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_colors.dart';
import '../../../core/theme.dart';
import '../data/chat_shell_mock.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat/chat_app_bar.dart';
import '../widgets/chat/chat_input_bar.dart';
import '../widgets/chat/deaver_bubble.dart';
import '../widgets/chat/image_bubble.dart';
import '../widgets/chat/quick_reply_list.dart';
import '../widgets/chat/system_notice.dart';
import '../widgets/chat/typing_indicator.dart';
import '../widgets/chat/user_bubble.dart';

/// 케이스 채팅 · 일반 채팅 공용 셸
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.caseNo, this.intent});

  final String caseNo;

  /// Cases 배너에서 넘어올 때 어느 시나리오로 열지
  final String? intent;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 시나리오 주입 — intent 로 시작 지점 결정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(chatThreadsProvider.notifier).load(const [mockShellThread]);
      ref
          .read(chatMessagesProvider(widget.caseNo).notifier)
          .load(mockShellMessages);
      ref
          .read(quickRepliesProvider(widget.caseNo).notifier)
          .replace(mockShellQuickReplies);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// 칩 탭 → 사용자 버블 → 타이핑 → Deaver 응답 → 상태 전이
  Future<void> _onQuickReply(String text) async {
    final messages = ref.read(chatMessagesProvider(widget.caseNo).notifier);
    final chips = ref.read(quickRepliesProvider(widget.caseNo).notifier);

    messages.add(ChatMessage.user(text));
    chips.clear();
    messages.add(const ChatMessage.typing());
    _scrollToBottom();

    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final turn = mockShellTurns[text];
    messages.removeTyping();

    if (turn == null) {
      _scrollToBottom();
      return;
    }

    messages.append(turn.messages);
    chips.replace(turn.quickReplies);

    // 전이 알림 문구는 목업에 있음 — 여기서는 배지만 갱신
    final nextStage = turn.nextCaseStage;
    if (nextStage != null) {
      ref
          .read(chatThreadsProvider.notifier)
          .updateCaseStage(widget.caseNo, nextStage);
    }
    _scrollToBottom();
  }

  /// 앞 메시지도 Deaver 면 아바타 생략
  bool _showAvatarAt(List<ChatMessage> list, int index) {
    if (list[index].type != MessageType.deaver) return false;
    if (index == 0) return true;
    return list[index - 1].type != MessageType.deaver;
  }

  Widget _buildMessage(ChatMessage message, bool showAvatar) {
    return switch (message.type) {
      MessageType.system => SystemNotice(text: message.text),
      MessageType.user => UserBubble(
        text: message.text,
        sentVia: message.sentVia,
      ),
      MessageType.image => ImageBubble(path: message.imagePath!),
      MessageType.typing => const TypingIndicator(),
      MessageType.deaver => DeaverBubble(
        text: message.text,
        card: message.card,
        draftText: message.draftText,
        showAvatar: showAvatar,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final thread = ref.watch(chatThreadProvider(widget.caseNo));
    final messages = ref.watch(chatMessagesProvider(widget.caseNo));
    final replies = ref.watch(quickRepliesProvider(widget.caseNo));

    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ChatAppBar(
              title: thread?.caseTitle ?? 'New chat',
              subtitle: _subtitleFor(thread),
              badge: thread?.caseStage?.headerBadge,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: Gap.md),
                // +1 = 칩 영역 — 메시지와 함께 스크롤
                itemCount: messages.length + 1,
                // 칩 블록 직전만 좁게
                separatorBuilder: (context, index) => SizedBox(
                  height: index == messages.length - 1 ? Gap.card : Gap.md,
                ),
                itemBuilder: (context, index) {
                  if (index == messages.length) {
                    return QuickReplyList(
                      replies: replies,
                      onTap: _onQuickReply,
                    );
                  }
                  return _buildMessage(
                    messages[index],
                    _showAvatarAt(messages, index),
                  );
                },
              ),
            ),
            const ChatInputBar(),
          ],
        ),
      ),
    );
  }

  String _subtitleFor(ChatThread? thread) {
    if (thread == null) return 'General question';
    final location = thread.caseLocation;
    final caseNo = thread.caseNo ?? widget.caseNo;
    return location == null ? 'Case #$caseNo' : 'Case #$caseNo · $location';
  }
}
