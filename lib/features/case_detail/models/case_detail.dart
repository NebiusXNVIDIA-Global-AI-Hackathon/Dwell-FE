import '../../cases/models/case_model.dart';
import 'checklist_item.dart';
import 'evidence_group.dart';
import 'timeline_step.dart';

class CaseDetail {
  const CaseDetail({
    required this.id,
    required this.caseNumber,
    required this.title,
    required this.location,
    required this.affectedArea,
    required this.address,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.currentStatusText,
    required this.timeline,
    required this.checklist,
    required this.evidence,
    this.statusIllustrationPath,
  });

  final String id;
  final String caseNumber;
  final String title;
  final String location;
  final String affectedArea;
  final String address;
  final CaseStatus status;
  final CaseSeverity priority;
  final DateTime createdAt;
  final String currentStatusText;
  final List<TimelineStepData> timeline;
  final List<ChecklistItem> checklist;
  final List<EvidenceGroup> evidence;
  final String? statusIllustrationPath;

  String get headline => '$title in $location · $affectedArea';

  CaseDetail copyWith({List<ChecklistItem>? checklist}) => CaseDetail(
    id: id,
    caseNumber: caseNumber,
    title: title,
    location: location,
    affectedArea: affectedArea,
    address: address,
    status: status,
    priority: priority,
    createdAt: createdAt,
    currentStatusText: currentStatusText,
    timeline: timeline,
    checklist: checklist ?? this.checklist,
    evidence: evidence,
    statusIllustrationPath: statusIllustrationPath,
  );
}
