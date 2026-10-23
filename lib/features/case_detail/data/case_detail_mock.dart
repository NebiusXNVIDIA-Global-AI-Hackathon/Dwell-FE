import '../../cases/data/mock_cases.dart';
import '../../cases/models/case_model.dart';
import '../../home/data/home_mock_data.dart';
import '../models/case_detail.dart';
import '../models/case_stage.dart';
import '../models/checklist_item.dart';
import '../models/evidence_group.dart';
import 'case_stage_mock.dart';

const mockCaseAddress = '123 Main St, Apt 4B';

// Look up a case from the Reports and Home mock sources
CaseDetail? findMockCaseDetail(String caseId) {
  for (final item in mockCases) {
    if (item.id == caseId) return mockCaseDetailFrom(item);
  }
  for (final item in homeCases) {
    if (item.caseItem.id == caseId) return mockCaseDetailFrom(item.caseItem);
  }
  return null;
}

CaseDetail mockCaseDetailFrom(CaseModel item) {
  final createdAt = item.createdAt.hour == 0
      ? item.createdAt.add(const Duration(hours: 10))
      : item.createdAt;
  final stage = initialStageFor(item.id);
  final content = caseStageContent(stage, createdAt: createdAt);

  return CaseDetail(
    id: item.id,
    caseNumber: _caseNumber(item.id),
    title: item.title,
    location: item.location,
    affectedArea: item.affectedArea,
    address: mockCaseAddress,
    status: item.status,
    priority: item.severity,
    createdAt: createdAt,
    stage: stage,
    banner: content.banner,
    timeline: content.timeline,
    timelineHasEarlierSteps: content.timelineHasEarlierSteps,
    checklist: _checklist(item.id, stage, content.checklist),
    evidence: [
      EvidenceGroup(
        id: '${item.id}-evidence-0',
        itemCount: item.evidenceList.isEmpty ? 3 : item.evidenceList.length,
        capturedAt: createdAt,
      ),
    ],
  );
}

// Swap in the banner, timeline and checklist for a stage
CaseDetail withStage(CaseDetail detail, CaseStage stage) {
  final content = caseStageContent(stage, createdAt: detail.createdAt);
  return detail.copyWith(
    stage: stage,
    banner: content.banner,
    timeline: content.timeline,
    timelineHasEarlierSteps: content.timelineHasEarlierSteps,
    checklist: _checklist(detail.id, stage, content.checklist),
  );
}

List<ChecklistItem> _checklist(
  String caseId,
  CaseStage stage,
  List<String> texts,
) => [
  for (final (index, text) in texts.indexed)
    ChecklistItem(id: '$caseId-${stage.name}-$index', text: text),
];

String _caseNumber(String id) {
  if (id.startsWith('C-')) return id;
  final digits = id.split('-').last;
  return 'C-$digits';
}
