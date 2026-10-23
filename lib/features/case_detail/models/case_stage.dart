/// Where a case is in the tenant workflow; drives the banner, timeline and checklist.
enum CaseStage {
  created,
  waitingResponse,
  responseOverdue,
  scheduling,
  followUpWaiting,
  followUpOverdue,
  repairScheduled,
  repairDay,
  repairInProgress,
  landlordRefused,
  blameShifting,
  reported311,
  hpdInspection,
  violationIssued,
  resolved,
  recurred,
  selfRepair,
  repairCostClaim,
  insuranceClaim,
}

enum CaseStageBadge { logged, inProgress, resolved }

extension CaseStageBadgeX on CaseStage {
  CaseStageBadge get badge => switch (this) {
    CaseStage.created ||
    CaseStage.waitingResponse ||
    CaseStage.followUpWaiting => CaseStageBadge.logged,
    CaseStage.resolved => CaseStageBadge.resolved,
    _ => CaseStageBadge.inProgress,
  };
}
