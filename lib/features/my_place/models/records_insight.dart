import 'data_status.dart';
import 'open_closed_count.dart';

/// 카테고리별 민원 수
class CategoryCount {
  final String category;
  final int count;

  const CategoryCount({required this.category, required this.count});
}

/// 월별 민원 수
class MonthCount {
  /// `yyyy-MM`
  final String month;
  final int count;

  const MonthCount({required this.month, required this.count});
}

/// Records 탭 — 건물 공공기록
class RecordsInsight {
  final DataStatus status;
  final int periodYears;
  final OpenClosedCount complaints;
  final OpenClosedCount violations;

  /// 추세를 보여주는 최소 기록 수
  final int minimumRequired;

  /// 많은 순. 기록이 부족하면 빈 목록
  final List<CategoryCount> complaintsByCategory;

  /// 최근 1년 3회 이상 반복된 민원 — 막대에서 주황으로 칠하는 대상
  final CategoryCount? repeatedIssue;

  /// 최근 36개월, 오래된 순
  final List<MonthCount> complaintsPerMonth;
  final String source;

  const RecordsInsight({
    required this.status,
    required this.periodYears,
    required this.complaints,
    required this.violations,
    required this.minimumRequired,
    required this.source,
    this.complaintsByCategory = const [],
    this.complaintsPerMonth = const [],
    this.repeatedIssue,
  });

  int get recordCount => complaints.total + violations.total;
}
