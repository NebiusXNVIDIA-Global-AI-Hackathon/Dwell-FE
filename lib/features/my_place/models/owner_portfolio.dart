/// 같은 소유주의 건물 1채 — Owner 탭 · Other buildings
class OwnerBuilding {
  final String address;
  final String borough;
  final int units;
  final int open;
  final int closed;
  final int classC;

  /// `↻ Heat ×4` — 있을 때만
  final String? repeatIssue;
  final int? repeatCount;

  /// 현재 사는 건물. 목록에 포함하되 강조하지 않는다
  final bool isThisBuilding;

  const OwnerBuilding({
    required this.address,
    required this.borough,
    required this.units,
    required this.open,
    required this.closed,
    required this.classC,
    this.repeatIssue,
    this.repeatCount,
    this.isThisBuilding = false,
  });
}

/// Owner 탭 집계 — 건물 목록에서 파생
class OwnerPortfolio {
  final List<OwnerBuilding> buildings;
  final bool hasEnoughData;

  const OwnerPortfolio({required this.buildings, required this.hasEnoughData});

  int get buildingCount => buildings.length;

  int get open {
    var total = 0;
    for (final building in buildings) {
      total += building.open;
    }
    return total;
  }

  int get closed {
    var total = 0;
    for (final building in buildings) {
      total += building.closed;
    }
    return total;
  }

  int get violations => open + closed;

  /// 진행바 채움 비율 — 기록이 없으면 0
  double get openRatio => violations == 0 ? 0 : open / violations;
}
