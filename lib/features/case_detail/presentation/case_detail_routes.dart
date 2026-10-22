abstract final class CaseDetailRoutes {
  static const detail = 'case-detail';
  static const timeline = 'case-detail-timeline';
  static const analysis = 'case-detail-analysis';
  static const notice = 'case-detail-notice';
  static const addEvidence = 'case-detail-add-evidence';

  static Map<String, String> params(String caseId) => {'caseId': caseId};
}
