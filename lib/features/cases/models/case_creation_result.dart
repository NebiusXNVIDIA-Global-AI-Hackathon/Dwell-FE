import 'case_model.dart';
import 'evidence_analysis_input.dart';

/// Presentation only. Demo values never enter CaseModel, Reports, or storage.
final class CaseCreationResult {
  CaseCreationResult.demo(this.input, {DateTime? previewedAt})
    : isDemo = true,
      id = 'DEMO-006',
      title =
          input.draft.specificIssue == 'Other' ||
              input.draft.specificIssue == 'Other Appliance'
          ? input.draft.otherIssue.trim()
          : input.draft.specificIssue ?? input.draft.issueType ?? '',
      location = input.draft.location == 'Other'
          ? input.draft.otherLocation.trim()
          : input.draft.location ?? '',
      affectedArea = input.draft.affectedArea == 'Other'
          ? input.draft.otherAffectedArea.trim()
          : input.draft.affectedArea ?? '',
      createdAt = previewedAt ?? DateTime.now(),
      severity = null,
      originalFileSaved = false,
      analysisAttached = false,
      tamperProtectionConfirmed = false;

  /// API integration must supply the real case and each independently verified
  /// completion flag. None is inferred from progress completion or severity.
  CaseCreationResult.confirmed(
    this.input,
    CaseModel caseItem, {
    required this.originalFileSaved,
    required this.analysisAttached,
    required this.tamperProtectionConfirmed,
  }) : isDemo = false,
       id = caseItem.id,
       title = caseItem.title,
       location = caseItem.location,
       affectedArea = caseItem.affectedArea,
       createdAt = caseItem.createdAt,
       severity = caseItem.severity;

  final EvidenceAnalysisInput input;
  final bool isDemo;
  final String id, title, location, affectedArea;
  final DateTime createdAt;
  final CaseSeverity? severity;
  final bool originalFileSaved, analysisAttached, tamperProtectionConfirmed;
  String get severityLabel => switch (severity) {
    CaseSeverity.low => 'Low',
    CaseSeverity.medium => 'Medium',
    CaseSeverity.high => 'High',
    null => 'Not assessed',
  };
  String get locationSummary =>
      [location, affectedArea].where((part) => part.isNotEmpty).join(' · ');
}
