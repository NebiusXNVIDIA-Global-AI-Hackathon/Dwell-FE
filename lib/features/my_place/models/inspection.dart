import 'issue_category.dart';
import 'localized_text.dart';

/// 체크 항목 — 저장할 때 key 를 보낸다
class Symptom {
  final String key;
  final LocalizedText label;

  const Symptom({required this.key, required this.label});
}

/// Check My Unit 체크리스트
class InspectionGuide {
  final int signalId;
  final IssueCategory category;

  /// `Radiator not heating · based on 3 neighbor reports`
  final String subtitle;
  final List<Symptom> symptoms;

  const InspectionGuide({
    required this.signalId,
    required this.category,
    required this.subtitle,
    required this.symptoms,
  });
}

/// 점검 결과로 채워지는 케이스 입력값
class CasePrefill {
  final IssueCategory category;

  /// 증상 → 세부 이슈 매핑이 아직 없어 비어 있을 수 있다
  final String? issueDetail;
  final String patternText;

  const CasePrefill({
    required this.category,
    required this.patternText,
    this.issueDetail,
  });
}

/// 체크 결과 저장 응답
class InspectionResult {
  final int inspectionId;
  final int matchedSigns;
  final CasePrefill prefill;

  const InspectionResult({
    required this.inspectionId,
    required this.matchedSigns,
    required this.prefill,
  });
}
