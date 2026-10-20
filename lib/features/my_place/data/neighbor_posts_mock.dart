// 커뮤니티 글 — 시그널 상세는 이슈 태그로 걸러 쓴다
// 사진은 서버가 URL 로 준다. 그때까지 자리만 잡아 둔다

import '../models/neighbor_post.dart';

/// 서버 URL 이 들어오기 전까지의 자리
const pendingThumbnail = 'pending';

final mockNeighborPosts = <NeighborPost>[
  NeighborPost(
    postId: 1,
    board: PostBoard.tips,
    floorBand: PostFloorBand.lower,
    title: 'Bucket + towel trick for a dripping ceiling',
    preview: 'Put a towel in the bucket to stop splashing, and…',
    body:
        'Put a towel in the bucket so the drip stops echoing all night. '
        'Mark the stain edge with a pencil and date it — that is what the '
        'inspector asked me for later.',
    tags: ['#ceilingleak', '#tempfix'],
    likeCount: 12,
    replyCount: 4,
    createdAt: DateTime(2026, 10, 5),
    thumbnailUrl: pendingThumbnail,
  ),
  NeighborPost(
    postId: 2,
    board: PostBoard.freeBoard,
    floorBand: PostFloorBand.middle,
    title: 'Floor 5 — our leak came back after repair',
    preview: 'Same line as yours? The plumber said it is the riser pipe…',
    body:
        'Same line as yours? The plumber said it is the riser pipe between '
        'floors 5 and 6, so patching the ceiling did not hold. It was back in '
        'two weeks.',
    tags: ['#ceilingleak', '#floor5'],
    likeCount: 8,
    replyCount: 6,
    createdAt: DateTime(2026, 10, 3),
    isMine: true,
  ),
  NeighborPost(
    postId: 3,
    board: PostBoard.freeBoard,
    floorBand: PostFloorBand.middle,
    title: 'Ceiling stain keeps growing',
    preview: 'It was the size of a coin last week…',
    body:
        'It was the size of a coin last week and now it reaches the light '
        'fixture. Management says they will send someone this week.',
    tags: ['#ceilingleak'],
    likeCount: 2,
    replyCount: 1,
    createdAt: DateTime(2026, 10, 4),
  ),
  NeighborPost(
    postId: 4,
    board: PostBoard.tips,
    floorBand: PostFloorBand.upper,
    title: 'Bleeding the radiator fixed our cold mornings',
    preview: 'Ours was warm at the bottom only — trapped air, not the boiler.',
    body:
        'Ours was warm at the bottom only, which turned out to be trapped air '
        'and not the boiler. Open the valve until it hisses, close it when '
        'water comes out.',
    tags: ['#radiator', '#noheat'],
    likeCount: 15,
    replyCount: 7,
    createdAt: DateTime(2026, 10, 9),
    thumbnailUrl: pendingThumbnail,
  ),
  NeighborPost(
    postId: 5,
    board: PostBoard.freeBoard,
    floorBand: PostFloorBand.lower,
    title: 'Anyone else lose hot water last night?',
    preview: 'Nothing but cold from 9pm. Super said he would look at it.',
    body:
        'Nothing but cold water from about 9pm. The super said he would look '
        'at the boiler in the morning. Logging it here so we have the date if '
        'it keeps happening.',
    tags: ['#noheat', '#boiler'],
    likeCount: 6,
    replyCount: 9,
    createdAt: DateTime(2026, 10, 11),
  ),
  NeighborPost(
    postId: 6,
    board: PostBoard.tips,
    floorBand: PostFloorBand.middle,
    title: 'Sealing the gap under the sink cut the roaches',
    preview: 'Foam around the pipe collar helped more than any spray.',
    body:
        'Foam around the pipe collar helped more than any spray. They come up '
        'the kitchen stack, so blocking that gap is worth doing before the '
        'building treats the line.',
    tags: ['#roaches', '#pests'],
    likeCount: 11,
    replyCount: 3,
    createdAt: DateTime(2026, 9, 30),
  ),
  NeighborPost(
    postId: 7,
    board: PostBoard.freeBoard,
    floorBand: PostFloorBand.upper,
    title: 'Roaches in the trash room again',
    preview: 'Two by the chute this morning. Reported it to the super.',
    body:
        'Two by the chute this morning. Reported it to the super and took a '
        'photo with the time showing. Keep your bags closed until it is '
        'treated.',
    tags: ['#roaches', '#pests'],
    likeCount: 4,
    replyCount: 2,
    createdAt: DateTime(2026, 10, 8),
  ),
];
