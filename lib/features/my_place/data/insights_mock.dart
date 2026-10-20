// Insights 4탭 · HPD History · Other buildings
// 저데이터 변형은 같은 화면의 다른 입력 — 숫자를 0 으로 채운 것이 아니다

import '../models/data_status.dart';
import '../models/hpd_history.dart';
import '../models/landlord_insight.dart';
import '../models/landlord_post_summary.dart';
import '../models/neighbor_post.dart';
import '../models/open_closed_count.dart';
import '../models/owner_portfolio.dart';
import '../models/records_insight.dart';
import 'landlord_posts_mock.dart';

const mockLandlordInsight = LandlordInsight(
  trackRecord: TrackRecord(
    rating: LandlordRating.slowToFix,
    avgDaysToFix: 47,
    nycAvgDaysToFix: 30,
    gaugeMaxDays: 90,
    fixedViolations: 5,
    minimumRequired: 3,
    violations: OpenClosedCount(total: 7, open: 2, closed: 5),
    classC: OpenClosedCount(total: 1, open: 1, closed: 0),
    source: 'Source: NYC HPD violations, 3 yrs · computed',
  ),
  followUpTimer: FollowUpTimer(
    defaultHours: 72,
    appliedHours: 48,
    reason: FollowUpReason.shortened,
  ),
);

const mockLandlordInsightLowData = LandlordInsight(
  trackRecord: TrackRecord(
    rating: LandlordRating.notEnoughData,
    nycAvgDaysToFix: 30,
    gaugeMaxDays: 90,
    fixedViolations: 1,
    minimumRequired: 3,
    violations: OpenClosedCount(total: 2, open: 1, closed: 1),
    classC: OpenClosedCount(total: 0, open: 0, closed: 0),
    source: 'Source: NYC HPD · 1 closed violation (3+ needed)',
  ),
  followUpTimer: FollowUpTimer(
    defaultHours: 72,
    appliedHours: 72,
    reason: FollowUpReason.notEnoughHistory,
  ),
);

// 민원 18건이 36개월에 퍼진 모양 — 겨울에 몰린다
const _monthlyCounts = <int>[
  0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, //
  0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 2, 1, //
  1, 2, 0, 0, 0, 0, 0, 0, 1, 2, 1, 2, //
];

/// 2023-11 부터 36개월
List<MonthCount> _monthlySeries() {
  final series = <MonthCount>[];
  var year = 2023;
  var month = 11;
  for (final count in _monthlyCounts) {
    series.add(
      MonthCount(
        month: '$year-${month.toString().padLeft(2, '0')}',
        count: count,
      ),
    );
    month++;
    if (month > 12) {
      month = 1;
      year++;
    }
  }
  return series;
}

final mockRecordsInsight = RecordsInsight(
  status: DataStatus.ok,
  periodYears: 3,
  complaints: const OpenClosedCount(total: 18, open: 6, closed: 12),
  violations: const OpenClosedCount(total: 7, open: 2, closed: 5),
  minimumRequired: 3,
  complaintsByCategory: const [
    CategoryCount(category: 'Water leak', count: 6),
    CategoryCount(category: 'Heat / hot water', count: 5),
    CategoryCount(category: 'Pests', count: 4),
    CategoryCount(category: 'Mold', count: 3),
  ],
  repeatedIssue: const CategoryCount(category: 'Water leak', count: 3),
  complaintsPerMonth: _monthlySeries(),
  source: 'Source: NYC HPD · updated daily',
);

const mockRecordsInsightLowData = RecordsInsight(
  status: DataStatus.notEnoughData,
  periodYears: 3,
  complaints: OpenClosedCount(total: 2, open: 0, closed: 2),
  violations: OpenClosedCount(total: 0, open: 0, closed: 0),
  minimumRequired: 3,
  source: 'Source: NYC HPD · updated daily',
);

// 12분기 — 민원 18 · 위반 7 로 Records 탭 합계와 맞춘다
const _quarterCounts = <QuarterCount>[
  QuarterCount(quarter: '2024Q1', complaints: 1, violations: 0),
  QuarterCount(quarter: '2024Q2', complaints: 0, violations: 0),
  QuarterCount(quarter: '2024Q3', complaints: 1, violations: 1),
  QuarterCount(quarter: '2024Q4', complaints: 1, violations: 0),
  QuarterCount(quarter: '2025Q1', complaints: 1, violations: 0),
  QuarterCount(quarter: '2025Q2', complaints: 2, violations: 1),
  QuarterCount(quarter: '2025Q3', complaints: 1, violations: 0),
  QuarterCount(quarter: '2025Q4', complaints: 2, violations: 1),
  QuarterCount(quarter: '2026Q1', complaints: 2, violations: 1),
  QuarterCount(quarter: '2026Q2', complaints: 3, violations: 1),
  QuarterCount(quarter: '2026Q3', complaints: 2, violations: 1),
  QuarterCount(quarter: '2026Q4', complaints: 2, violations: 1),
];

const mockHpdHistory = HpdHistory(
  source: 'Source: NYC HPD violations · 3 yrs',
  periodYears: 3,
  complaints: OpenClosedCount(total: 18, open: 6, closed: 12),
  violations: OpenClosedCount(total: 7, open: 2, closed: 5),
  violationsByClass: [
    ViolationClassCount(violationClass: 'Class A', total: 3, open: 0),
    ViolationClassCount(violationClass: 'Class B', total: 3, open: 1),
    ViolationClassCount(violationClass: 'Class C', total: 1, open: 1),
  ],
  perQuarter: _quarterCounts,
  hpdOnlineUrl: 'https://hpdonline.nyc.gov',
);

const mockOwnerPortfolio = OwnerPortfolio(
  hasEnoughData: true,
  buildings: [
    OwnerBuilding(
      address: '418 E 23rd St',
      borough: 'Manhattan',
      units: 24,
      open: 9,
      closed: 11,
      classC: 3,
      repeatIssue: 'Heat',
      repeatCount: 4,
    ),
    OwnerBuilding(
      address: '77 Avenue A',
      borough: 'Manhattan',
      units: 18,
      open: 6,
      closed: 10,
      classC: 1,
      repeatIssue: 'Pests',
      repeatCount: 3,
    ),
    OwnerBuilding(
      address: '1240 Amsterdam Ave',
      borough: 'Manhattan',
      units: 32,
      open: 4,
      closed: 7,
      classC: 0,
    ),
    OwnerBuilding(
      address: '245 W 107th St',
      borough: 'Manhattan',
      units: 20,
      open: 2,
      closed: 5,
      classC: 1,
      repeatIssue: 'Water leak',
      repeatCount: 3,
      isThisBuilding: true,
    ),
  ],
);

const mockOwnerPortfolioLowData = OwnerPortfolio(
  hasEnoughData: false,
  buildings: [
    OwnerBuilding(
      address: '245 W 107th St',
      borough: 'Manhattan',
      units: 20,
      open: 2,
      closed: 5,
      classC: 1,
      isThisBuilding: true,
    ),
  ],
);

/// Tenants 탭 — 글 목록에서 집계한다. 숫자를 따로 적지 않는다
LandlordPostSummary buildLandlordPostSummary(List<NeighborPost> posts) {
  final counts = {for (final topic in PostTopic.values) topic: 0};
  for (final post in posts) {
    final topic = post.landlordTopic;
    if (topic != null) counts[topic] = counts[topic]! + 1;
  }

  final preview = [...posts]
    ..sort((a, b) => b.likeCount.compareTo(a.likeCount));

  const minimum = 3;
  final enough = posts.length >= minimum;

  return LandlordPostSummary(
    status: enough ? DataStatus.ok : DataStatus.notEnoughData,
    postCount: posts.length,
    minimumRequired: minimum,
    topicCounts: counts,
    previewPosts: enough ? preview.take(3).toList() : const [],
  );
}

final mockLandlordPostSummary = buildLandlordPostSummary(mockLandlordPosts);

const landlordPostsSource =
    'Source: Neighbor Community · posts mentioning the landlord · anonymous';
