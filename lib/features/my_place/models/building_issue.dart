/// 건물에서 번지는 이슈 — Rising Issue 카드 · 시그널 상세 · Check My Unit 의 원천
class BuildingIssue {
  final String id;

  /// "Heating system not working" — 카드 제목
  final String title;

  /// "Water leak" — 시그널 상세 제목에 붙는 짧은 이름
  final String issueType;
  final int reportCount;

  /// 시그널 상세의 Deaver's insight 본문 — 단정형 금지
  final String deaverInsight;

  /// Check My Unit 체크 항목
  final List<String> checkItems;

  /// 이웃 글을 이 이슈로 끌어오는 태그
  final List<String> postTags;

  const BuildingIssue({
    required this.id,
    required this.title,
    required this.issueType,
    required this.reportCount,
    required this.deaverInsight,
    required this.checkItems,
    required this.postTags,
  });
}
