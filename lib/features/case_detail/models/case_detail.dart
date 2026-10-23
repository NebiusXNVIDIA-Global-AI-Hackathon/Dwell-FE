import '../../cases/models/case_model.dart';
import 'case_stage.dart';
import 'checklist_item.dart';
import 'evidence_group.dart';
import 'status_banner.dart';
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
    required this.stage,
    required this.banner,
    required this.timeline,
    this.timelineHasEarlierSteps = false,
    required this.checklist,
    required this.evidence,
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
  final CaseStage stage;
  final StatusBanner banner;
  final List<TimelineStepData> timeline;
  final bool timelineHasEarlierSteps;
  final List<ChecklistItem> checklist;
  final List<EvidenceGroup> evidence;

  String get headline => '$title in $location · $affectedArea';

  CaseDetail copyWith({
    CaseStage? stage,
    StatusBanner? banner,
    List<TimelineStepData>? timeline,
    bool? timelineHasEarlierSteps,
    List<ChecklistItem>? checklist,
  }) => CaseDetail(
    id: id,
    caseNumber: caseNumber,
    title: title,
    location: location,
    affectedArea: affectedArea,
    address: address,
    status: status,
    priority: priority,
    createdAt: createdAt,
    stage: stage ?? this.stage,
    banner: banner ?? this.banner,
    timeline: timeline ?? this.timeline,
    timelineHasEarlierSteps:
        timelineHasEarlierSteps ?? this.timelineHasEarlierSteps,
    checklist: checklist ?? this.checklist,
    evidence: evidence,
  );
}
