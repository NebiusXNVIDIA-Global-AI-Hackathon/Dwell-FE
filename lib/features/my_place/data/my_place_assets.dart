// 에셋 경로 — 위젯에 문자열 박지 않기

import '../models/issue_category.dart';

/// 시그널 목록 대표 카드의 Deaver 일러스트
const signalPatternIllustration = 'assets/images/deaver_building_signal.png';

/// 이슈 카테고리 아이콘 — New Case 위저드와 같은 에셋을 쓴다
const _issueIcons = <IssueCategory, String>{
  IssueCategory.heatHotWater: 'assets/icons/issues/heat.svg',
  IssueCategory.waterFlooding: 'assets/icons/issues/water.svg',
  IssueCategory.plumbing: 'assets/icons/issues/plumbing.svg',
  IssueCategory.moldMoisture: 'assets/icons/issues/mold.svg',
  IssueCategory.pests: 'assets/icons/issues/pests.svg',
  IssueCategory.electricity: 'assets/icons/issues/electricity.svg',
  IssueCategory.gas: 'assets/icons/issues/gas.svg',
  IssueCategory.appliances: 'assets/icons/issues/appliances.svg',
  IssueCategory.ventilation: 'assets/icons/issues/ventilation.svg',
  IssueCategory.safety: 'assets/icons/issues/safety.svg',
};

String issueIconPath(IssueCategory category) => _issueIcons[category]!;
