// Bring in a case — 아직 채팅이 없는 케이스만

import '../models/case_stage.dart';

/// 선택 목록 한 줄
class SelectableCase {
  final String caseNo;
  final String title;
  final String location;
  final String createdLabel;
  final CaseStage stage;

  const SelectableCase({
    required this.caseNo,
    required this.title,
    required this.location,
    required this.createdLabel,
    required this.stage,
  });
}

const mockSelectableCases = <SelectableCase>[
  SelectableCase(
    caseNo: 'C-004',
    title: 'Mold on bathroom wall',
    location: 'Bathroom',
    createdLabel: '9/28/2026',
    stage: CaseStage.logged,
  ),
  SelectableCase(
    caseNo: 'C-003',
    title: 'Radiator knocking',
    location: 'Bedroom',
    createdLabel: '9/24/2026',
    stage: CaseStage.logged,
  ),
];
