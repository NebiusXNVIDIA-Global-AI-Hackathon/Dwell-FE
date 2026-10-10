// 전 화면 공통 데모 값 — 주소가 화면마다 다르게 박히는 사고 방지

const demoUserName = 'Seohu Jang';
const demoUserInitials = 'SJ';
const demoAddress = '254 W 107th St, Apt 4B, New York, NY 10025';
const demoLandlordName = 'John Smith';
const demoLandlordHonorific = 'Mr. Smith';

// 데모 기준 케이스 — 와프 전체가 이 케이스로 그려져 있음
const demoCaseNo = 'C-006';
const demoCaseTitle = 'Water Leak';
const demoCaseLocation = 'Bathroom · Ceiling';

// SLA — My Place > Building Insights > Landlord 탭과 같은 값을 읽음
const slaResponseWindow = Duration(hours: 24);
const slaFollowUpWindow = Duration(hours: 24);

/// 집주인 이력 충분 + 위험도 높음 → 단축
const slaFollowUpTimerShortened = Duration(hours: 48);

/// 이력 부족 → 기본 유지
const slaFollowUpTimerStandard = Duration(hours: 72);

const slaShortenedReason =
    'Because the risk for this landlord is High, '
    'I set the response deadline to 48 hours instead of 72.';
