import '../../cases/models/case_model.dart';

/// 케이스 세부 진행 단계 21종
///
/// 팀원 `CaseStatus`(목록 탭 3종)와 별개 — [toListStatus] 로 파생
enum CaseStage {
  logged,
  notifiedLandlord,
  waitingResponse,
  responseOverdue,
  followUpSent,
  escalatedNoResponse,
  reportedTo311,
  hpdInspection,
  violationIssued,
  notFixedByDeadline,
  scheduling,
  repairScheduled,
  repairDay,
  repairInProgress,
  resolved,
  disputedNotFixed,
  disputedBlameShift,
  recurred,
  repairingMyself,
  claimSent,
  insuranceClaimFiled;

  /// System 알림 문구 — "Case C-006 updated: {label} → {label}"
  String get label => switch (this) {
    CaseStage.logged => 'Logged',
    CaseStage.notifiedLandlord => 'Notified Landlord',
    CaseStage.waitingResponse => 'Waiting for response',
    CaseStage.responseOverdue => 'Response Overdue',
    CaseStage.followUpSent => 'Follow-up Sent',
    CaseStage.escalatedNoResponse => 'Escalated (No response)',
    CaseStage.reportedTo311 => 'Reported to 311',
    CaseStage.hpdInspection => 'HPD Inspection',
    CaseStage.violationIssued => 'Violation Issued',
    CaseStage.notFixedByDeadline => 'Not Fixed by deadline',
    CaseStage.scheduling => 'Scheduling',
    CaseStage.repairScheduled => 'Repair Scheduled',
    CaseStage.repairDay => 'Repair Day',
    CaseStage.repairInProgress => '1st Visit logged',
    CaseStage.resolved => 'Resolved',
    CaseStage.disputedNotFixed => 'Disputed (Still not fixed)',
    CaseStage.disputedBlameShift => 'Disputed (Blame shifting)',
    CaseStage.recurred => 'Recurred (linked)',
    CaseStage.repairingMyself => 'Repairing myself',
    CaseStage.claimSent => 'Claim Sent',
    CaseStage.insuranceClaimFiled => 'Insurance Claim Filed',
  };

  /// 채팅 헤더 배지 — 21종을 12종으로 압축
  String get headerBadge => switch (this) {
    CaseStage.logged => 'Logged',
    CaseStage.notifiedLandlord ||
    CaseStage.waitingResponse ||
    CaseStage.followUpSent => 'Waiting',
    CaseStage.responseOverdue => 'Overdue',
    CaseStage.escalatedNoResponse ||
    CaseStage.reportedTo311 ||
    CaseStage.hpdInspection ||
    CaseStage.violationIssued => 'Escalated',
    CaseStage.notFixedByDeadline ||
    CaseStage.disputedNotFixed ||
    CaseStage.disputedBlameShift => 'Disputed',
    CaseStage.scheduling => 'Scheduling',
    CaseStage.repairScheduled => 'Scheduled',
    CaseStage.repairDay => 'Repair Day',
    CaseStage.repairInProgress || CaseStage.repairingMyself => 'In Progress',
    CaseStage.resolved => 'Resolved',
    CaseStage.recurred => 'Recurred',
    CaseStage.claimSent || CaseStage.insuranceClaimFiled => 'Claim',
  };
}

/// 목록 탭 분류 파생 — 팀원 `CaseStatus` 는 수정하지 않음
CaseStatus toListStatus(CaseStage stage) => switch (stage) {
  CaseStage.logged => CaseStatus.logged,
  CaseStage.resolved => CaseStatus.resolved,
  _ => CaseStatus.active,
};
