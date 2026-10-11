// 케이스 채팅 진입 직후 목업

import '../models/case_stage.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';
import '../models/chat_turn.dart';
import '../models/info_card.dart';

const mockShellThread = ChatThread(
  id: 'C-005', // 케이스 채팅은 스레드 id = 케이스 번호
  kind: ChatKind.caseChat,
  title: 'No heat · C-005',
  preview: 'Deaver: I\u2019ve loaded your no-heat case.',
  timeLabel: '2m',
  caseNo: 'C-005',
  caseTitle: 'No heat',
  caseLocation: 'Living Room',
  caseStage: CaseStage.logged,
);

const mockShellMessages = <ChatMessage>[
  ChatMessage.system('Today 9:12 AM'),
  ChatMessage.deaver(
    'I\u2019ve loaded your no-heat case. Your landlord hasn\u2019t been '
    'notified yet, and heat season started Oct 1. '
    'What would you like to do first?',
  ),
];

const mockShellQuickReplies = <String>[
  'Draft a notice to my landlord',
  'What are my rights for heat?',
  'Tips to stay warm while I wait',
];

/// 칩 탭 → 응답
const mockShellTurns = <String, ChatTurn>{
  'What are my rights for heat?': ChatTurn(
    messages: [
      ChatMessage.deaver(
        'During heat season (Oct 1 \u2013 May 31), your landlord must keep '
        'your apartment warm:',
        card: InfoCard(
          label: 'NYC HEAT RULES',
          lines: [
            'Day (6am\u201310pm): at least 68\u00B0F when it\u2019s below '
                '55\u00B0F outside',
            'Night (10pm\u20136am): at least 62\u00B0F',
          ],
          sourceText:
              'Source: NYC Housing Maintenance Code \u00A727-2029 \u2197',
          footnote:
              'This may be your landlord\u2019s duty. '
              'A written notice is usually the first step.',
        ),
      ),
    ],
    quickReplies: [
      'Draft a notice to my landlord',
      'Start a temperature log',
      'How do I file with 311?',
    ],
  ),
  'Draft a notice to my landlord': ChatTurn(
    messages: [
      ChatMessage.system('Case C-005 updated: Logged \u2192 Notified Landlord'),
      ChatMessage.deaver(
        'Here\u2019s a notice you can send. Review it before opening Messages.',
        draftText:
            'Hi Mr. Smith, this is Seohu in Unit 4B. There has been no heat '
            'since Oct 1. Could you please have it repaired as soon as '
            'possible?',
      ),
    ],
    quickReplies: ['Open in Messages', 'Edit message'],
    nextCaseStage: CaseStage.notifiedLandlord,
  ),
};
