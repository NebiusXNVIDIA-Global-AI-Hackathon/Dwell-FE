// 점검 결과를 들고 들어오는 상담 — 케이스 번호가 없는 준케이스 채팅

import '../models/chat_message.dart';
import '../models/chat_turn.dart';
import 'chat_scenarios.dart';

const noEvidenceReply = "I don't have evidence yet";

/// 바퀴벌레는 와프에 응답 본문이 있다
const _roachNextSteps =
    'Check tonight. Turn on the kitchen light after dark and take a photo '
    'or video if you see any.\n'
    'Look for signs. Check under sinks, behind the fridge, and inside '
    'cabinets for droppings or egg cases.\n'
    'Seal food and trash. Keep food in sealed containers and take out trash '
    'daily.\n'
    'Ask for pest control. In NYC, your landlord is responsible for pest '
    'control. You can request it in writing even before it gets worse.';

/// 그 밖의 이슈는 기록 · 서면 요청까지만 안내한다
const _generalNextSteps =
    'Write down what you see. Note the date and time each time it happens — '
    'that record is what a notice is built on.\n'
    'Take a photo or short video. Even one clear shot helps later.\n'
    'Ask in writing. A text or email leaves a dated record, and asking for '
    'repairs is protected in NYC.';

ChatScenario inspectionChatScenario({
  required String issueKey,
  required List<String> symptoms,
}) {
  final noticed = symptoms.map(_lowerFirst).join(' and ');
  final steps = issueKey == 'pests' ? _roachNextSteps : _generalNextSteps;

  return ChatScenario(
    messages: [
      ChatMessage.deaver(
        'You noticed $noticed. Can you upload a few photos and tell me where '
        'and when you see them most',
      ),
    ],
    quickReplies: const [noEvidenceReply],
    turns: {
      noEvidenceReply: ChatTurn(
        messages: [
          const ChatMessage.deaver(
            "That's okay. Since this has already been reported in your "
            "building, it's worth acting early before it spreads. Here's what "
            'you can do now.',
          ),
          ChatMessage.deaver(steps),
        ],
      ),
    },
  );
}

String _lowerFirst(String text) =>
    text.isEmpty ? text : text[0].toLowerCase() + text.substring(1);
