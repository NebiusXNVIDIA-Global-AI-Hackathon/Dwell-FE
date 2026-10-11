// 일반 채팅 — 모국어 질문 · 케이스 생성 제안

import '../models/chat_message.dart';
import '../models/chat_turn.dart';
import '../models/info_card.dart';
import 'shared_mock.dart';

const mockGeneralMessages = <ChatMessage>[
  ChatMessage.deaver(
    'Hi $demoUserFirstName! Ask me anything about your home, your rights, '
    'or a message from your landlord. You can write in any language.',
  ),
];

const mockGeneralQuickReplies = <String>[
  'Can my landlord enter without notice?',
  'Translate a letter from my landlord',
  'How do I file with 311?',
];

/// 칩 탭 → 응답
const mockGeneralTurns = <String, ChatTurn>{
  'Can my landlord enter without notice?': ChatTurn(
    messages: [
      ChatMessage.deaver(
        'In NYC, landlords generally need to give reasonable notice before '
        'entering, except in an emergency.',
        card: InfoCard(
          label: 'WHAT THE RULE SAYS',
          lines: [
            'Non-emergency entry: reasonable advance notice',
            'Emergency (fire, flood, gas): no notice needed',
          ],
          sourceText: 'Source: NYC Housing Maintenance Code §27-2008 ↗',
          footnote:
              'This is general information, not legal advice. '
              'A written record of each visit request helps.',
        ),
      ),
    ],
    quickReplies: ['How do I file with 311?', '집주인이 연락을 안 받아요'],
  ),
  'How do I file with 311?': ChatTurn(
    messages: [
      ChatMessage.deaver(
        'Filing online is fastest. You describe the problem, the location in '
        'your unit, and your address.',
        card: InfoCard(
          label: 'HOW TO FILE',
          lines: [
            '1. Go to the 311 repair complaint form',
            '2. Pick the problem and the location in your unit',
            '3. Submit and save the SR number',
          ],
          sourceText: '311 Online · portal.311.nyc.gov ↗',
          footnote: 'HPD usually schedules an inspection within 1–2 weeks.',
        ),
      ),
    ],
    quickReplies: ['Can my landlord enter without notice?'],
  ),
  // 모국어 질문 → 모국어 답변 + 영어 의미
  '집주인이 연락을 안 받아요': ChatTurn(
    messages: [
      ChatMessage.deaver(
        '"We’ll look into it"은 날짜를 어진 게 '
        '아니에요. 확인해 보겠다는 '
        '반이들 분, 수리 일정이 '
        '정해진 건 아니에요.',
        card: InfoCard(
          label: 'ENGLISH MEANING',
          lines: ['"We’ll check on it" — not a promise or a date.'],
        ),
      ),
      ChatMessage.deaver(
        '어떤 문제인지 알려주시면 '
        '다음 단계를 같이 '
        '정리해 드릴게요.',
      ),
    ],
    quickReplies: [
      '욕실 벽에 곰팡이가 '
          '계속 번져요',
    ],
  ),
  // 케이스 생성 제안
  '욕실 벽에 곰팡이가 계속 번져요': ChatTurn(
    messages: [
      ChatMessage.deaver(
        '곰팡이는 건강에 어향을 '
        '주 수 있어서 기록을 남기는 '
        '게 좋아요. 이 내용으로 '
        '케이스를 만들까요?',
        card: InfoCard(
          label: "WE'LL FILL IN",
          lines: [
            'Issue: Mold & Moisture · Visible mold',
            'Location: Bathroom · Wall',
            'Landlord contacted: "We’ll look into it" (7 days ago)',
          ],
        ),
      ),
    ],
    quickReplies: ['Create a case', 'Just keep chatting'],
  ),
  'Just keep chatting': ChatTurn(
    messages: [
      ChatMessage.deaver(
        '알았어요. 필요해지면 '
        '언제든 말씀해 주세요.',
      ),
    ],
  ),
};
