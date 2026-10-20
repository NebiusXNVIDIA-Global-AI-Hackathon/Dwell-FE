/// 전체 · 진행 · 종결 묶음 — 민원 · 위반이 모두 이 모양
class OpenClosedCount {
  final int total;
  final int open;
  final int closed;

  const OpenClosedCount({
    required this.total,
    required this.open,
    required this.closed,
  });

  /// 진행 비율 — 기록이 없으면 0
  double get openRatio => total == 0 ? 0 : open / total;
}
