// My Place 메인 · 시그널 상세 · Check My Unit

import '../models/building_signal.dart';
import '../models/inspection.dart';
import '../models/issue_category.dart';
import '../models/localized_text.dart';
import '../models/neighbor_post.dart';
import 'neighbor_posts_mock.dart';

const demoBuildingAddress = '245 W 107th St, Apt 4B, New York, NY 10025';
const demoBuildingBbl = '1-01863-0029';

/// 호수를 뺀 건물 주소 — 목록 부제에 쓴다
const demoBuildingAddressShort = '245 W 107th St';

const mockAllSignals = <BuildingSignal>[
  BuildingSignal(
    signalId: 101,
    category: IssueCategory.heatHotWater,
    title: 'Heating system not working',
    issueLabel: 'Heating Issues',
    description: 'A few neighbors reported no heat. Check your unit too.',
    reportCount: 3,
  ),
  BuildingSignal(
    signalId: 102,
    category: IssueCategory.pests,
    title: 'Roaches reported in several units',
    issueLabel: 'Roaches',
    description: 'A few neighbors reported pest activity.',
    reportCount: 2,
  ),
  BuildingSignal(
    signalId: 103,
    category: IssueCategory.waterFlooding,
    title: 'Water leak spreading on upper floors',
    issueLabel: 'Water Leak',
    description: 'Neighbors on your line reported ceiling drips.',
    reportCount: 5,
  ),
];

const mockPrimarySignal = PrimarySignal(
  signalId: 103,
  category: IssueCategory.waterFlooding,
  title: 'Water leak spreading on upper floors',
  issueLabel: 'Water Leak',
  reportCount: 5,
  reportedIn: ['Bathroom', 'Ceiling', 'Kitchen'],
  windowLabel: '2 months',
  relatedToMyCase: true,
);

/// 대표 패턴을 뺀 나머지 — 신고 많은 순
final mockRisingSignals = <BuildingSignal>[
  for (final signal in mockAllSignals)
    if (signal.signalId != mockPrimarySignal.signalId) signal,
]..sort((a, b) => b.reportCount.compareTo(a.reportCount));

final mockBuildingSignals = BuildingSignals(
  primary: mockPrimarySignal,
  risingIssues: mockRisingSignals,
);

// 시그널별 Deaver's insight — 단정형 금지
const _insights = <int, LocalizedText>{
  101: LocalizedText(
    'Reports come from different lines but all started after Oct 1 — '
        'this may be a central boiler issue. Check your radiators in the morning.',
    '서로 다른 라인에서 신고가 들어왔지만 모두 10월 1일 이후에 시작됐어요. '
        '중앙 보일러 문제일 수 있으니 아침에 라디에이터를 확인해 보세요.',
  ),
  102: LocalizedText(
    'Reports cluster around the kitchen stacks on three floors — '
        'this may travel through shared pipes. Sealing food helps, but the building needs treatment.',
    '세 개 층의 주방 배관 주변에 신고가 몰려 있어요. 공용 배관을 타고 이동하는 것일 수 있어요. '
        '음식을 밀봉하면 도움이 되지만 건물 차원의 방역이 필요해요.',
  ),
  103: LocalizedText(
    'Four units on the same line reported a ceiling drip within two weeks — '
        'this may be a riser pipe, not a problem in your unit. Photograph the stain before it dries.',
    '같은 라인 4세대가 2주 안에 천장 누수를 신고했어요. 집 안의 문제가 아니라 '
        '수직 배관 문제일 수 있어요. 자국이 마르기 전에 사진을 남겨 두세요.',
  ),
};

// 시그널 ↔ 글 연결 — 서버는 상세 응답에 글을 담아 보낸다
const _signalTags = <int, List<String>>{
  101: ['#noheat', '#radiator', '#boiler'],
  102: ['#roaches', '#pests'],
  103: ['#ceilingleak', '#waterleak', '#tempfix'],
};

// 짧은 이슈 이름 — 서버는 대표 시그널에만 issueLabel 을 준다
const _shortLabels = <int, String>{
  101: 'Heat',
  102: 'Roaches',
  103: 'Water leak',
};

String signalShortLabel(int signalId) =>
    _shortLabels[signalId] ?? IssueCategory.safety.label;

List<NeighborPost> postsForSignal(int signalId) {
  final tags = _signalTags[signalId] ?? const [];
  return [
    for (final post in mockNeighborPosts)
      if (post.tags.any(tags.contains)) post,
  ];
}

SignalDetail? signalDetailFor(int signalId) {
  for (final signal in mockAllSignals) {
    if (signal.signalId != signalId) continue;
    return SignalDetail(
      signalId: signal.signalId,
      category: signal.category,
      title: signal.category == IssueCategory.waterFlooding
          ? 'Water leak'
          : signal.title,
      relatedToMyCase: signal.signalId == mockPrimarySignal.signalId,
      insight: _insights[signal.signalId],
      posts: postsForSignal(signal.signalId),
    );
  }
  return null;
}

const mockInspectionGuides = <int, InspectionGuide>{
  101: InspectionGuide(
    signalId: 101,
    category: IssueCategory.heatHotWater,
    subtitle: 'Radiator not heating · based on 2 neighbor reports',
    symptoms: [
      Symptom(
        key: 'RADIATOR_COLD',
        label: LocalizedText(
          'Radiator is cold or lukewarm in the morning',
          '아침에 라디에이터가 차갑거나 미지근해요',
        ),
      ),
      Symptom(
        key: 'ROOM_BELOW_68',
        label: LocalizedText(
          'Room stays below 68°F during the day',
          '낮에도 실내가 68°F 아래예요',
        ),
      ),
      Symptom(
        key: 'NO_HOT_WATER',
        label: LocalizedText(
          'No hot water for more than 10 minutes',
          '10분 넘게 온수가 나오지 않아요',
        ),
      ),
      Symptom(
        key: 'PIPE_NOISE',
        label: LocalizedText(
          'Clanking or hissing noise from the pipes',
          '배관에서 쿵쿵거리거나 쉭쉭거리는 소리가 나요',
        ),
      ),
    ],
  ),
  102: InspectionGuide(
    signalId: 102,
    category: IssueCategory.pests,
    subtitle: 'Roaches reported · based on 3 neighbor reports',
    symptoms: [
      Symptom(
        key: 'ROACHES_SEEN',
        label: LocalizedText(
          'Roaches seen in the kitchen or bathroom',
          '주방이나 욕실에서 바퀴벌레를 봤어요',
        ),
      ),
      Symptom(
        key: 'DROPPINGS',
        label: LocalizedText(
          'Small dark droppings near sinks or cabinets',
          '싱크대나 수납장 근처에 작고 검은 배설물이 있어요',
        ),
      ),
      Symptom(
        key: 'EGG_CASES',
        label: LocalizedText(
          'Egg cases in corners or behind appliances',
          '구석이나 가전 뒤에 알집이 있어요',
        ),
      ),
      Symptom(
        key: 'ROACHES_AT_NIGHT',
        label: LocalizedText(
          'Roaches coming out at night when lights turn on',
          '밤에 불을 켜면 바퀴벌레가 나와요',
        ),
      ),
    ],
  ),
  103: InspectionGuide(
    signalId: 103,
    category: IssueCategory.waterFlooding,
    subtitle: 'Ceiling leak · based on 4 neighbor reports',
    symptoms: [
      Symptom(
        key: 'CEILING_STAIN',
        label: LocalizedText(
          'Water stain or bubbling paint on the ceiling',
          '천장에 물 자국이 있거나 페인트가 부풀었어요',
        ),
      ),
      Symptom(
        key: 'DRIP_RETURNS',
        label: LocalizedText(
          'A drip that comes back after it dries',
          '마른 뒤에도 다시 물이 떨어져요',
        ),
      ),
      Symptom(
        key: 'DAMP_SMELL',
        label: LocalizedText('Damp smell in the bathroom', '욕실에서 눅눅한 냄새가 나요'),
      ),
      Symptom(
        key: 'STAIN_GROWING',
        label: LocalizedText(
          'The stain is growing week to week',
          '자국이 주마다 커지고 있어요',
        ),
      ),
    ],
  ),
};
