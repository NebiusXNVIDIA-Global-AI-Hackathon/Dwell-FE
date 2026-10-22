import '../../cases/data/mock_cases.dart';
import '../../cases/models/case_model.dart';
import '../../home/data/home_mock_data.dart';
import '../models/case_detail.dart';
import '../models/timeline_step.dart';
import '../models/checklist_item.dart';
import '../models/evidence_group.dart';

const mockCaseAddress = '123 Main St, Apt 4B';

const _mockChecklist = [
  'Send written notice to your landlord',
  'Take timestamped photos of the issue',
  'Note when it’s getting worse',
];

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
    currentStatusText: 'Ready to notify your landlord',
    timeline: [
      TimelineStepData(
        label: 'Case\nCreated',
        state: TimelineStepState.completed,
        eventTitle: 'Case Created',
        description: 'You documented the leak in your bathroom ceiling with 2 photos and 1 video.',
        occurredAt: createdAt.add(const Duration(hours: 10, minutes: 12)),
      ),
      const TimelineStepData(
        label: 'Notified\nLandlord',
        state: TimelineStepState.current,
        eventTitle: 'Landlord Notified',
        description: 'Sent by text to John Smith (Landlord). Included the issue, location, date first noticed and evidence.',
      ),
      const TimelineStepData(
        label: 'Waiting for\nLandlord’s Response',
        state: TimelineStepState.upcoming,
      ),
    ],
    checklist: [
      for (final (index, text) in _mockChecklist.indexed)
        ChecklistItem(id: '${item.id}-check-$index', text: text),
    ],
    evidence: [
      EvidenceGroup(
        id: '${item.id}-evidence-0',
        itemCount: item.evidenceList.isEmpty ? 3 : item.evidenceList.length,
        capturedAt: createdAt,
      ),
    ],
  );
}

String _caseNumber(String id) {
  if (id.startsWith('C-')) return id;
  final digits = id.split('-').last;
  return 'C-$digits';
}
