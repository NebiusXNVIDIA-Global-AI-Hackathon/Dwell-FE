import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/case_stage.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';

/// 채팅 목록 — 목업 연결은 01 채팅 목록에서
final chatThreadsProvider =
    NotifierProvider<ChatThreadsNotifier, List<ChatThread>>(
      ChatThreadsNotifier.new,
    );

class ChatThreadsNotifier extends Notifier<List<ChatThread>> {
  @override
  List<ChatThread> build() => const [];

  void load(List<ChatThread> threads) => state = threads;

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
