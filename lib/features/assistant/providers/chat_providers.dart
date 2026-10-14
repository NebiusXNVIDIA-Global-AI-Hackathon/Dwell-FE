import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bring_in_case_mock.dart';
import '../data/chat_list_mock.dart';
import '../models/case_stage.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';

/// 채팅 목록
final chatThreadsProvider =
    NotifierProvider<ChatThreadsNotifier, List<ChatThread>>(
      ChatThreadsNotifier.new,
    );

class ChatThreadsNotifier extends Notifier<List<ChatThread>> {
  @override
  List<ChatThread> build() => const [
    ...mockCaseChatThreads,
    ...mockGeneralChatThreads,
  ];

  /// Leave 다이얼로그
  void remove(String id) => state = [
    for (final thread in state)
      if (thread.id != id) thread,
  ];

  /// 상태 전이 → 목록 타일·채팅 헤더 배지 갱신
  void updateCaseStage(String caseNo, CaseStage stage) {
    state = [
      for (final thread in state)
        if (thread.caseNo == caseNo)
          thread.copyWith(caseStage: stage)
        else
          thread,
    ];
  }

  /// 새 일반 채팅 — 첫 메시지가 생기면 목록 맨 위에
  void addGeneral(ChatThread thread) => state = [thread, ...state];

  /// Bring in a case — 고른 케이스로 채팅 시작
  void openCaseChat(SelectableCase item) {
    if (state.any((thread) => thread.caseNo == item.caseNo)) return;
    state = [
      ChatThread(
        id: item.caseNo,
        kind: ChatKind.caseChat,
        title: '${item.title} \u00B7 ${item.caseNo}',
        preview: 'Deaver: Ready when you are.',
        timeLabel: 'now',
        caseNo: item.caseNo,
        caseTitle: item.title,
        caseLocation: item.location,
        caseStage: item.stage,
      ),
      ...state,
    ];
  }

  void markRead(String id) => state = [
    for (final thread in state)
      if (thread.id == id) thread.copyWith(hasUnread: false) else thread,
  ];
}

/// 스레드 단건
final chatThreadProvider = Provider.family<ChatThread?, String>((ref, id) {
  for (final thread in ref.watch(chatThreadsProvider)) {
    if (thread.id == id) return thread;
  }
  return null;
});

/// 스레드별 메시지
final chatMessagesProvider =
    NotifierProvider.family<ChatMessagesNotifier, List<ChatMessage>, String>(
      ChatMessagesNotifier.new,
    );

class ChatMessagesNotifier extends Notifier<List<ChatMessage>> {
  ChatMessagesNotifier(this.threadId);

  final String threadId;

  @override
  List<ChatMessage> build() => const [];

  void load(List<ChatMessage> messages) => state = messages;

  void append(List<ChatMessage> messages) => state = [...state, ...messages];

  void add(ChatMessage message) => state = [...state, message];

  /// 응답 도착 시 타이핑 버블 제거
  void removeTyping() => state = [
    for (final message in state)
      if (message.type != MessageType.typing) message,
  ];
}

/// 현재 떠 있는 퀵리플라이
final quickRepliesProvider =
    NotifierProvider.family<QuickRepliesNotifier, List<String>, String>(
      QuickRepliesNotifier.new,
    );

class QuickRepliesNotifier extends Notifier<List<String>> {
  QuickRepliesNotifier(this.threadId);

  final String threadId;

  @override
  List<String> build() => const [];

  void replace(List<String> replies) => state = replies;

  void clear() => state = const [];
}

/// Bring in a case — 채팅이 아직 없는 케이스만
final selectableCasesProvider = Provider<List<SelectableCase>>((ref) {
  final taken = {
    for (final thread in ref.watch(chatThreadsProvider))
      if (thread.caseNo != null) thread.caseNo!,
  };

  return [
    for (final item in mockSelectableCases)
      if (!taken.contains(item.caseNo)) item,
  ];
});
