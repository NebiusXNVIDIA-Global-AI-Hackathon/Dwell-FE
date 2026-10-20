// 커뮤니티 전용 목업 — 댓글 · 최근 검색어 · 내 사건과 겹치는 태그 수
// 글 자체는 neighbor_posts_mock.dart 한 곳에서만 온다

import '../models/neighbor_post.dart';
import '../models/post_detail.dart';

/// 게시물별 댓글 — 닉네임은 서버가 주는 값 자리다
final mockPostReplies = <int, List<PostReply>>{
  2: [
    PostReply(
      replyId: 201,
      nickname: 'GuiltyMo',
      initials: 'GM',
      floorBand: PostFloorBand.lower,
      content: 'Same here. Ours started after the repair too.',
      createdAt: DateTime(2026, 10, 3, 18, 20),
    ),
    PostReply(
      replyId: 202,
      nickname: 'LeftMino',
      initials: 'LM',
      floorBand: PostFloorBand.upper,
      content: 'Ours came back in about two weeks as well.',
      createdAt: DateTime(2026, 10, 4, 9, 5),
    ),
    PostReply(
      replyId: 203,
      nickname: 'DORAI',
      initials: 'DI',
      floorBand: PostFloorBand.upper,
      content: 'Did they open the ceiling or just paint over the stain?',
      createdAt: DateTime(2026, 10, 4, 12, 40),
    ),
    PostReply(
      replyId: 204,
      nickname: 'Winterwolf',
      initials: 'WW',
      floorBand: PostFloorBand.middle,
      content: 'Take a photo every time it drips. Mine helped at the hearing.',
      createdAt: DateTime(2026, 10, 5, 8, 15),
    ),
    PostReply(
      replyId: 205,
      nickname: 'Quietbee',
      initials: 'QB',
      floorBand: PostFloorBand.lower,
      content: 'The super told us the riser is scheduled for next month.',
      createdAt: DateTime(2026, 10, 5, 19, 30),
    ),
    PostReply(
      replyId: 206,
      nickname: 'Mapletone',
      initials: 'MT',
      floorBand: PostFloorBand.middle,
      content: 'Mine is on the same line. Let me know if they come back.',
      createdAt: DateTime(2026, 10, 6, 11, 0),
    ),
  ],
  1: [
    PostReply(
      replyId: 211,
      nickname: 'Quietbee',
      initials: 'QB',
      floorBand: PostFloorBand.lower,
      content: 'The towel trick worked for us. No more noise at night.',
      createdAt: DateTime(2026, 10, 5, 21, 10),
    ),
    PostReply(
      replyId: 212,
      nickname: 'DORAI',
      initials: 'DI',
      floorBand: PostFloorBand.upper,
      content: 'Dating the stain edge is smart. Doing that tonight.',
      createdAt: DateTime(2026, 10, 6, 7, 45),
    ),
  ],
  3: [
    PostReply(
      replyId: 221,
      nickname: 'LeftMino',
      initials: 'LM',
      floorBand: PostFloorBand.upper,
      content: 'Ours grew the same way. Keep the photos with dates.',
      createdAt: DateTime(2026, 10, 4, 20, 0),
    ),
  ],
};

/// 검색 화면이 비어 있을 때 띄우는 최근 검색어
const mockRecentSearches = <String>['#noheat', '#dispute', '#tempfix'];

/// 내 사건과 겹치는 글 수 — 서버가 세어 주는 값이라 없는 태그는 안 센다
const mockTagRelatedToMyCase = <String, int>{'#ceilingleak': 3, '#noheat': 2};

/// 내가 쓰는 글 · 댓글의 표기 — 서버 연동 전까지의 자리
const mockMyNickname = 'SJ';
const mockMyInitials = 'SJ';
const mockMyFloorBand = PostFloorBand.middle;
