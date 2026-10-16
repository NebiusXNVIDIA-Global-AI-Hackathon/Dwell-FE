// Insights 4탭 · HPD History · Other buildings
// 저데이터 변형은 같은 화면의 다른 입력 — 숫자를 0 으로 채운 것이 아니다

import '../models/building_records.dart';
import '../models/landlord_record.dart';
import '../models/owner_portfolio.dart';

const mockLandlordRecord = LandlordRecord(
  avgDaysToFix: 47,
  cityAvgDaysToFix: 30,
  violationsOpen: 2,
  violationsTotal: 7,
  classCOpen: 1,
  followUpDefaultHours: 72,
  followUpActualHours: 48,
  hasEnoughData: true,
  fixedViolations: 5,
  requiredViolations: 3,
);

const mockLandlordRecordLowData = LandlordRecord(
  avgDaysToFix: 0,
  cityAvgDaysToFix: 30,
  violationsOpen: 1,
  violationsTotal: 2,
  classCOpen: 0,
  followUpDefaultHours: 72,
  followUpActualHours: 72,
  hasEnoughData: false,
  fixedViolations: 1,
  requiredViolations: 3,
);

// 민원 18건이 36개월에 퍼진 모양 — 겨울에 몰린다
const _monthlyComplaints = <int>[
  0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, //
  0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 2, 1, //
  1, 2, 0, 0, 0, 0, 0, 0, 1, 2, 1, 2, //
];

const _quarterly = <QuarterTally>[
  (complaints: 1, violations: 0),
  (complaints: 0, violations: 0),
  (complaints: 1, violations: 1),
  (complaints: 1, violations: 0),
  (complaints: 1, violations: 0),
  (complaints: 2, violations: 1),
  (complaints: 1, violations: 0),
  (complaints: 2, violations: 1),
  (complaints: 2, violations: 1),
  (complaints: 3, violations: 1),
  (complaints: 2, violations: 1),
  (complaints: 2, violations: 1),
];

const mockBuildingRecords = BuildingRecords(
  complaints: 18,
  complaintsOpen: 6,
  violations: 7,
  violationsOpen: 2,
  byCategory: {'Water leak': 6, 'Heat / hot water': 5, 'Pests': 4, 'Mold': 3},
  repeatCategory: 'Water leak',
  repeatCount: 3,
  monthlySeries: _monthlyComplaints,
  byClass: [
    (label: 'Class A', total: 3, open: 0),
    (label: 'Class B', total: 3, open: 1),
    (label: 'Class C', total: 1, open: 1),
  ],
  quarterly: _quarterly,
  quarterlyStartYear: 2024,
  hasEnoughData: true,
);

const mockBuildingRecordsLowData = BuildingRecords(
  complaints: 2,
  complaintsOpen: 0,
  violations: 0,
  violationsOpen: 0,
  byCategory: {},
  monthlySeries: [],
  byClass: [],
  quarterly: [],
  quarterlyStartYear: 2024,
  hasEnoughData: false,
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

/// Records · HPD History 출처 문구
const hpdRecordsSource = 'Source: NYC HPD · updated daily';
const hpdViolationsSource = 'Source: NYC HPD violations · 3 yrs';
const hpdOnlineUrl = 'https://hpdonline.nyc.gov';
