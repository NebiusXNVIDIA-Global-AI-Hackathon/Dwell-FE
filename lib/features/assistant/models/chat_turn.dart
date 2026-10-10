import 'case_stage.dart';
import 'chat_message.dart';

/// 사용자 입력 1회에 대한 Deaver 응답 묶음
class ChatTurn {
  final List<ChatMessage> messages;
  final List<String> quickReplies;

  /// 있으면 상태 전이
  final CaseStage? nextCaseStage;

  const ChatTurn({
    this.messages = const [],
    this.quickReplies = const [],
    this.nextCaseStage,
  });
}
