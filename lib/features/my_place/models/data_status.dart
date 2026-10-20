/// 집계를 보여줄 만큼 기록이 쌓였는지 — 부족하면 점수를 만들지 않는다
enum DataStatus { ok, notEnoughData }

extension DataStatusX on DataStatus {
  bool get hasEnoughData => this == DataStatus.ok;
}
