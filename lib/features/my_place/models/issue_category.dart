/// 이슈 카테고리 — 시그널 · 점검 · 케이스 프리필이 같은 값을 쓴다
enum IssueCategory {
  heatHotWater('Heat & Hot Water'),
  waterFlooding('Water & Flooding'),
  plumbing('Plumbing'),
  moldMoisture('Mold & Moisture'),
  pests('Pests'),
  electricity('Electricity'),
  gas('Gas'),
  appliances('Appliances'),
  ventilation('Ventilation'),
  safety('Safety');

  const IssueCategory(this.label);

  /// 화면 · 케이스 위저드 1단계 표기
  final String label;
}
