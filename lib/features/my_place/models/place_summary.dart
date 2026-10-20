import 'building_signal.dart';

/// My Place 메인 — 주소 + Rising Issue 카드
class PlaceSummary {
  /// 호수 포함
  final String address;

  /// NYC Borough-Block-Lot
  final String bbl;
  final List<BuildingSignal> risingIssues;

  const PlaceSummary({
    required this.address,
    required this.bbl,
    required this.risingIssues,
  });
}
