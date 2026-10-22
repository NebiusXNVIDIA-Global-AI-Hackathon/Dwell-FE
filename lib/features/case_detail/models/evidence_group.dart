class EvidenceGroup {
  const EvidenceGroup({
    required this.id,
    required this.itemCount,
    required this.capturedAt,
    this.thumbnailPath,
  });

  final String id;
  final int itemCount;
  final DateTime capturedAt;
  final String? thumbnailPath;
}
