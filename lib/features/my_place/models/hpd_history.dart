import 'open_closed_count.dart';

/// 등급별 위반 — A / B / C
class ViolationClassCount {
  final String violationClass;
  final int total;
  final int open;

  const ViolationClassCount({
    required this.violationClass,
    required this.total,
    required this.open,
  });
}

/// 분기별 민원 · 위반
class QuarterCount {
  /// `2024Q1`
  final String quarter;
  final int complaints;
  final int violations;

  const QuarterCount({
    required this.quarter,
    required this.complaints,
    required this.violations,
  });
}

/// HPD History Overview
class HpdHistory {
  final String source;
  final int periodYears;
  final OpenClosedCount complaints;
  final OpenClosedCount violations;
  final List<ViolationClassCount> violationsByClass;

  /// 최근 12분기, 오래된 순
  final List<QuarterCount> perQuarter;
  final String hpdOnlineUrl;

  const HpdHistory({
    required this.source,
    required this.periodYears,
    required this.complaints,
    required this.violations,
    required this.violationsByClass,
    required this.perQuarter,
    required this.hpdOnlineUrl,
  });
}
