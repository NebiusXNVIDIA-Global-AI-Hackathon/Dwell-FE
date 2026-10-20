// 집주인 언급 글 — Insights Tenants 집계 · Posts about landlord 목록
// 주제별 개수가 두 화면의 타일·탭 숫자가 된다

import '../models/neighbor_post.dart';

final mockLandlordPosts = <NeighborPost>[
  NeighborPost(
    postId: 11,
    board: PostBoard.freeBoard,
    floorBand: PostFloorBand.middle,
    title: 'Landlord took 3 weeks to send a plumber',
    preview: 'Asked twice in writing before anyone came to look at it.',
    body:
        'Asked twice in writing before anyone came to look at it. Keep your '
        'texts — the dates were the only reason the second request got a '
        'response.',
    tags: ['#waterleak'],
    likeCount: 14,
    replyCount: 6,
    createdAt: DateTime(2026, 10, 2),
    landlordTopic: PostTopic.slowRepairs,
  ),
  NeighborPost(
    postId: 12,
    board: PostBoard.freeBoard,
    floorBand: PostFloorBand.lower,
    title: 'Six weeks for a bathroom ceiling patch',
    preview: 'It was painted over twice before they opened the ceiling.',
    body:
        'It was painted over twice before they finally opened the ceiling. '
        'Photograph it every week — the repaint is what makes it look fixed.',
    tags: ['#ceilingleak'],
    likeCount: 9,
    replyCount: 4,
    createdAt: DateTime(2026, 9, 27),
    landlordTopic: PostTopic.slowRepairs,
  ),
  NeighborPost(
    postId: 13,
    board: PostBoard.freeBoard,
    floorBand: PostFloorBand.upper,
    title: 'Still waiting on the radiator since September',
    preview: 'Two visits, no parts. Heat season started without it.',
    body:
        'Two visits and no parts either time. Heat season started without it, '
        'so I filed with 311 and the date finally moved.',
    tags: ['#radiator', '#noheat'],
    likeCount: 7,
    replyCount: 5,
    createdAt: DateTime(2026, 10, 6),
    landlordTopic: PostTopic.slowRepairs,
  ),
  NeighborPost(
    postId: 14,
    board: PostBoard.freeBoard,
    floorBand: PostFloorBand.middle,
    title: 'Mold came back a month after the "repair"',
    preview: 'They wiped the wall and repainted. It is back in the corner.',
    body:
        'They wiped the wall and repainted, which lasted about a month. It is '
        'back in the same corner, so I am logging it as a repeat this time.',
    tags: ['#mold'],
    likeCount: 11,
    replyCount: 8,
    createdAt: DateTime(2026, 10, 10),
    landlordTopic: PostTopic.slowRepairs,
  ),
  NeighborPost(
    postId: 15,
    board: PostBoard.freeBoard,
    floorBand: PostFloorBand.lower,
    title: 'Roach treatment took a month to schedule',
    preview: 'Pest control came once and never did the follow-up visit.',
    body:
        'Pest control came once and never did the follow-up visit. Ask for '
        'the second treatment in writing — that is in the contract with the '
        'exterminator.',
    tags: ['#roaches', '#pests'],
    likeCount: 5,
    replyCount: 3,
    createdAt: DateTime(2026, 9, 22),
    landlordTopic: PostTopic.slowRepairs,
  ),
  NeighborPost(
    postId: 16,
    board: PostBoard.freeBoard,
    floorBand: PostFloorBand.upper,
    title: 'No answer to three emails about the leak',
    preview: 'Sent photos each time. Nothing back for two weeks.',
    body:
        'Sent photos each time and nothing came back for two weeks. The '
        'management line goes to voicemail after 5pm, so email is the only '
        'record I have.',
    tags: ['#ceilingleak', '#waterleak'],
    likeCount: 13,
    replyCount: 7,
    createdAt: DateTime(2026, 10, 7),
    landlordTopic: PostTopic.noReply,
  ),
  NeighborPost(
    postId: 17,
    board: PostBoard.freeBoard,
    floorBand: PostFloorBand.middle,
    title: 'Texts read, never answered',
    preview: 'Read receipts on, no reply. Sending letters now.',
    body:
        'Read receipts on and no reply for a week. I switched to a written '
        'letter so there is something with a date on it.',
    tags: ['#noheat'],
    likeCount: 6,
    replyCount: 2,
    createdAt: DateTime(2026, 10, 1),
    landlordTopic: PostTopic.noReply,
  ),
  NeighborPost(
    postId: 18,
    board: PostBoard.freeBoard,
    floorBand: PostFloorBand.lower,
    title: 'Voicemail box was full all week',
    preview: 'Could not reach anyone about the hot water.',
    body:
        'Could not reach anyone about the hot water — the box was full all '
        'week. The super gave me a direct number eventually.',
    tags: ['#boiler', '#noheat'],
    likeCount: 4,
    replyCount: 1,
    createdAt: DateTime(2026, 9, 24),
    landlordTopic: PostTopic.noReply,
  ),
  NeighborPost(
    postId: 19,
    board: PostBoard.freeBoard,
    floorBand: PostFloorBand.upper,
    title: 'Pipe was replaced properly after the second visit',
    preview: 'Took a while, but they opened the wall and swapped the section.',
    body:
        'Took a while, but they opened the wall and swapped the section '
        'instead of patching it. No stain since. Worth asking for the riser '
        'to be checked.',
    tags: ['#waterleak'],
    likeCount: 18,
    replyCount: 9,
    createdAt: DateTime(2026, 9, 18),
    landlordTopic: PostTopic.fixedWell,
  ),
];
