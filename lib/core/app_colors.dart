import 'package:material_ui/material_ui.dart';

// colorScheme 으로 커버 안 되는 고정 색
abstract final class AppColors {
  // 브랜드
  static const navy = Color(0xFF243B53); // 헤더 배경 · 주 버튼 · 활성 탭 (= theme seed)
  static const link = Color(0xFF0065F3); // 법 조항 출처 링크
  static const unreadDot = Color(0xFFF58A00); // 채팅 미읽음 점
  static const danger = Color(0xFFFF3D3D); // 나가기 등 파괴적 동작

  // 면
  static const bg = Color(0xFFF8F8F8); // 페이지 배경
  static const headerSubtle = Color(
    0xFFF5F5F5,
  ); // 네이비 헤더 부제 (= scaffoldBackgroundColor)
  static const surface = Color(0xFFFFFFFF); // 카드 · 타일 · 시트

  // 말풍선
  static const bubbleAi = Color(0xFFCBD4D8); // Deaver
  static const bubbleUser = Color(0xFFD8D5CB); // 사용자
  static const infoCard = Color(0xFFE1E6E8); // 버블 안 카드

  // 글자
  static const textStrong = Color(0xFF152332); // 말풍선 본문
  static const textTitle = Color(0xFF243B53); // 제목
  static const textBody = Color(0xFF5E5E5E);
  static const textMuted = Color(0xFFA8A8A8); // 비활성 탭 · 시간
  static const textSubtle = Color(0xFF667685); // 페이지 부제 · 카드 보조
  static const cardBody = Color(0xFF000000); // 버블 안 카드 본문

  // 선 · 보조
  static const divider = Color(0xFFE5E5E5);
  static const inputBorder = Color(0xFFCBCBCB); // 채팅 입력바 테두리
  static const systemPill = Color(0xFFE4E8EC); // System pill 배경
  // 상태 배지 배경은 divider 와 같은 값 — 별도 상수 없음
  static const iconGray = Color(0xFF8F8F8F); // 첨부 + 버튼
  static const iconFaint = Color(0xFFD3D1D1); // 섹션 옆 안내 아이콘
  static const scrim = Color(0x331A1A1A); // 모달 · 다이얼로그 뒤 배경
}
