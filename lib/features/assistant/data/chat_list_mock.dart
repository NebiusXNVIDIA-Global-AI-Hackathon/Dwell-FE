// 채팅 목록 — 케이스 채팅 2 + 일반 채팅 2

import '../models/case_stage.dart';
import '../models/chat_thread.dart';

const mockCaseChatThreads = <ChatThread>[
  ChatThread(
    id: 'C-006',
    kind: ChatKind.caseChat,
    title: 'Water Leak · C-006',
    preview: 'Deaver: If anything else needs updating, just let…',
    timeLabel: '2m',
    hasUnread: true,
    caseNo: 'C-006',
    caseTitle: 'Water leak',
    caseLocation: 'Bathroom ceiling',
    caseStage: CaseStage.waitingResponse,
  ),
  ChatThread(
    id: 'C-005',
    kind: ChatKind.caseChat,
    title: 'No heat · C-005',
    preview: 'Deaver: If anything else needs updating, just let…',
    timeLabel: '2m',
    hasUnread: true,
    caseNo: 'C-005',
    caseTitle: 'No heat',
    caseLocation: 'Living Room',
    caseStage: CaseStage.logged,
  ),
];

const mockGeneralChatThreads = <ChatThread>[
  ChatThread(
    id: 'g-001',
    kind: ChatKind.general,
    title: '집주인이 연락을 안 받아요',
    preview: 'Deaver: 걱정 마세요. 먼저 서면 통지를…',
    timeLabel: 'Sep 30',
  ),
  ChatThread(
    id: 'g-002',
    kind: ChatKind.general,
    title: 'Can my landlord enter without notice?',
    preview: 'Deaver: In NYC, landlords generally need..',
    timeLabel: 'Sep 30',
  ),
];

/// 새 일반 채팅 — 첫 메시지가 생기면 목록에 추가
const newGeneralThreadId = 'new-general';
