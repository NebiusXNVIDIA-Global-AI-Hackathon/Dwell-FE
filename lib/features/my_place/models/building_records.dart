/// 위반 등급별 집계 — HPD History 도넛 · 범례
typedef ViolationClassTally = ({String label, int total, int open});

/// 분기별 집계 — HPD History 그룹 막대
typedef QuarterTally = ({int complaints, int violations});

/// Insights Records 탭 · HPD History — 건물 공공기록
class BuildingRecords {
  final int complaints;
  final int complaintsOpen;
  final int violations;
  final int violationsOpen;

  /// 카테고리별 민원 수 — 선언 순서가 막대 순서
  final Map<String, int> byCategory;

  /// 반복 카테고리 — 막대에서 주황으로 칠하는 대상. 순위와 무관
  final String? repeatCategory;
  final int? repeatCount;

  /// 36개월 민원 추이 — 스파크라인
  final List<int> monthlySeries;

  final List<ViolationClassTally> byClass;

  /// 12분기 — 가장 오래된 분기부터
  final List<QuarterTally> quarterly;

  /// 분기 축 라벨의 시작 연도
  final int quarterlyStartYear;

  final bool hasEnoughData;

  /// 저데이터 — `2 of 3 records` 에 쓰는 필요 건수
  final int requiredRecords;

  const BuildingRecords({
    required this.complaints,
    required this.complaintsOpen,
    required this.violations,
    required this.violationsOpen,
    required this.byCategory,
    required this.monthlySeries,
    required this.byClass,
    required this.quarterly,
    required this.quarterlyStartYear,
    required this.hasEnoughData,
    this.repeatCategory,
    this.repeatCount,
    this.requiredRecords = 3,
  });

  int get complaintsClosed => complaints - complaintsOpen;
  int get violationsClosed => violations - violationsOpen;
}
