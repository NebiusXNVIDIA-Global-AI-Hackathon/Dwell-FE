import 'open_closed_count.dart';

/// Landlord 탭 배지
enum LandlordRating {
  fixesQuickly('Fixes quickly'),
  aboutAverage('About average'),
  slowToFix('Slow to fix'),
  notEnoughData('Not enough data');

  const LandlordRating(this.label);

  final String label;
}

/// Follow-up timer 가 왜 그 값인지
enum FollowUpReason {
  shortened('Shortened for this landlord'),
  standard('Standard for this landlord'),
  notEnoughHistory('Standard — not enough history');

  const FollowUpReason(this.label);

  final String label;
}

/// 집주인 수리 기록
class TrackRecord {
  final LandlordRating rating;

  /// 종결 위반이 기준치에 못 미치면 null
  final int? avgDaysToFix;
  final int nycAvgDaysToFix;
  final int gaugeMaxDays;

  /// 계산에 쓴 종결 위반 수
  final int fixedViolations;
  final int minimumRequired;

  final OpenClosedCount violations;
  final OpenClosedCount classC;
  final String source;

  const TrackRecord({
    required this.rating,
    required this.nycAvgDaysToFix,
    required this.gaugeMaxDays,
    required this.fixedViolations,
    required this.minimumRequired,
    required this.violations,
    required this.classC,
    required this.source,
    this.avgDaysToFix,
  });

  bool get hasEnoughData => avgDaysToFix != null;

  /// 시 평균보다 느리면 위험색
  bool get isSlowerThanCity => (avgDaysToFix ?? 0) > nycAvgDaysToFix;

  /// 임계치 바에 남은 건수
  int get remainingForScore =>
      (minimumRequired - fixedViolations).clamp(0, minimumRequired);
}

/// 재통지 대기 시간 — Assistant SLA 문구가 같은 값을 읽는다
class FollowUpTimer {
  final int defaultHours;
  final int appliedHours;
  final FollowUpReason reason;

  const FollowUpTimer({
    required this.defaultHours,
    required this.appliedHours,
    required this.reason,
  });

  bool get isShortened => appliedHours < defaultHours;
}

class LandlordInsight {
  final TrackRecord trackRecord;
  final FollowUpTimer followUpTimer;

  const LandlordInsight({
    required this.trackRecord,
    required this.followUpTimer,
  });
}
