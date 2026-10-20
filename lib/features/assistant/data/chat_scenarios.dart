// caseNo → 시나리오. 위젯은 Provider 만 보고 이 파일을 직접 읽지 않는다

import '../models/chat_message.dart';
import '../models/chat_turn.dart';
import 'chat_list_mock.dart';
import 'chat_shell_mock.dart';
import 'general_chat_mock.dart';

/// 한 스레드의 시작 상태와 응답 묶음
class ChatScenario {
  final List<ChatMessage> messages;
  final List<String> quickReplies;
  final Map<String, ChatTurn> turns;

  const ChatScenario({
    this.messages = const [],
    this.quickReplies = const [],
    this.turns = const {},
  });
}

const _caseC005 = ChatScenario(
  messages: mockShellMessages,
  quickReplies: mockShellQuickReplies,
  turns: mockShellTurns,
);

const _general = ChatScenario(
  messages: mockGeneralMessages,
  quickReplies: mockGeneralQuickReplies,
  turns: mockGeneralTurns,
);

const _byThreadId = <String, ChatScenario>{
  'C-005': _caseC005,
  newGeneralThreadId: _general,
  'g-001': _general,
  'g-002': _general,
};

// 대화에 사용자 입력이 섞이는 경우 — 화면을 열기 전에 등록해 둔다
final _runtime = <String, ChatScenario>{};

void registerScenario(String threadId, ChatScenario scenario) =>
    _runtime[threadId] = scenario;

/// 없는 스레드는 빈 시나리오 — 화면은 뜨고 대화만 비어 있음
ChatScenario scenarioFor(String threadId) =>
    _runtime[threadId] ?? _byThreadId[threadId] ?? const ChatScenario();
