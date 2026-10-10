/// 버블 안 카드 — 라벨만 다르고 위젯은 하나
class InfoCard {
  /// "REPAIR VISIT" / "VERDICT · VERIFIED" / "311 COMPLAINT"
  final String label;
  final List<String> lines;

  /// "311 Online · Repair complaint" 처럼 외부 출처 ↗
  final String? sourceText;

  /// 카드 아래 회색 보조 문장
  final String? footnote;

  const InfoCard({
    required this.label,
    required this.lines,
    this.sourceText,
    this.footnote,
  });
}
