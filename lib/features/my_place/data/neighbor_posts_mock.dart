// 커뮤니티 글 — 시그널 상세는 이슈 태그로 걸러 쓴다

import '../models/neighbor_post.dart';

final mockNeighborPosts = <NeighborPost>[
  NeighborPost(
    id: 'p-001',
    board: PostBoard.tips,
    floorBand: PostFloorBand.lower,
    title: 'Bucket + towel trick for a ceiling drip',
    excerpt: 'Put a towel in the bucket so the drip stops echoing all night.',
    body:
        'Put a towel in the bucket so the drip stops echoing all night. '
        'Mark the stain edge with a pencil and date it — that is what the '
        'inspector asked me for later.',
    tags: ['ceilingleak', 'tempfix'],
    likes: 12,
    replyCount: 4,
    postedAt: DateTime(2026, 10, 5),
  ),
  NeighborPost(
    id: 'p-002',
    board: PostBoard.freeBoard,
    floorBand: PostFloorBand.middle,
    title: 'Floor 5 — our leak came back after repair',
    excerpt: 'Same line as yours? The plumber said it is the riser pipe.',
    body:
        'Same line as yours? The plumber said it is the riser pipe between '
        'floors 5 and 6, so patching the ceiling did not hold. It was back in '
        'two weeks.',
    tags: ['ceilingleak', 'waterleak'],
    likes: 8,
    replyCount: 6,
    postedAt: DateTime(2026, 10, 3),
    isMine: true,
  ),
  NeighborPost(
    id: 'p-003',
    board: PostBoard.tips,
    floorBand: PostFloorBand.upper,
    title: 'Bleeding the radiator fixed our cold mornings',
    excerpt: 'Ours was warm at the bottom only — trapped air, not the boiler.',
    body:
        'Ours was warm at the bottom only, which turned out to be trapped air '
        'and not the boiler. Open the valve until it hisses, close it when '
        'water comes out.',
    tags: ['radiator', 'noheat'],
    likes: 15,
    replyCount: 7,
    postedAt: DateTime(2026, 10, 9),
  ),
  NeighborPost(
    id: 'p-004',
    board: PostBoard.freeBoard,
    floorBand: PostFloorBand.lower,
    title: 'Anyone else lose hot water last night?',
    excerpt: 'Nothing but cold from 9pm. Super said he would look at it.',
    body:
        'Nothing but cold water from about 9pm. The super said he would look '
        'at the boiler in the morning. Logging it here so we have the date if '
        'it keeps happening.',
    tags: ['noheat', 'boiler'],
    likes: 6,
    replyCount: 9,
    postedAt: DateTime(2026, 10, 11),
  ),
  NeighborPost(
    id: 'p-005',
    board: PostBoard.tips,
    floorBand: PostFloorBand.middle,
    title: 'Sealing the gap under the sink cut the roaches',
    excerpt: 'Foam around the pipe collar helped more than any spray.',
    body:
        'Foam around the pipe collar helped more than any spray. They come up '
        'the kitchen stack, so blocking that gap is worth doing before the '
        'building treats the line.',
    tags: ['roaches', 'pests'],
    likes: 11,
    replyCount: 3,
    postedAt: DateTime(2026, 9, 30),
  ),
  NeighborPost(
    id: 'p-006',
    board: PostBoard.freeBoard,
    floorBand: PostFloorBand.upper,
    title: 'Roaches in the trash room again',
    excerpt: 'Two by the chute this morning. Reported it to the super.',
    body:
        'Two by the chute this morning. Reported it to the super and took a '
        'photo with the time showing. Keep your bags closed until it is '
        'treated.',
    tags: ['roaches', 'pests'],
    likes: 4,
    replyCount: 2,
    postedAt: DateTime(2026, 10, 8),
  ),
];
