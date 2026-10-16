/// Insights Landlord 탭 — 집주인 이력
class LandlordRecord {
  final int avgDaysToFix;
  final int cityAvgDaysToFix;

  /// 게이지 스케일 상한
  final int maxDaysToFix;

  final int violationsOpen;
  final int violationsTotal;
  final int classCOpen;

  /// Follow-up timer — Assistant SLA 문구가 같은 값을 읽는다
  final int followUpDefaultHours;
  final int followUpActualHours;

  /// 점수를 만들 만큼 기록이 쌓였는지
  final bool hasEnoughData;

  /// 저데이터 — 임계치 바에 쓰는 현재 / 필요 건수
  final int fixedViolations;
  final int requiredViolations;

  const LandlordRecord({
    required this.avgDaysToFix,
    required this.cityAvgDaysToFix,
    required this.violationsOpen,
    required this.violationsTotal,
    required this.classCOpen,
    required this.followUpDefaultHours,
    required this.followUpActualHours,
    required this.hasEnoughData,
    required this.fixedViolations,
    required this.requiredViolations,
    this.maxDaysToFix = 90,
  });

  /// 시 평균보다 느리면 위험색
  bool get isSlowerThanCity => avgDaysToFix > cityAvgDaysToFix;

  /// 타이머가 단축됐는지
  bool get isFollowUpShortened => followUpActualHours < followUpDefaultHours;
}
