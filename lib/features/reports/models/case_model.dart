enum CaseStatus { active, logged, resolved }

enum CaseSeverity { low, medium, high }

class CaseModel {
  final String id;
  final String title;
  final CaseStatus status;
  final CaseSeverity severity;
  final String issueType;
  final String location;
  final String affectedArea;
  final bool isPublic;
  final String? thumbnailUrl;
  final bool isVideo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CaseModel({
    required this.id,
    required this.title,
    required this.status, //Active / Logged / Resolved 탭 구분
    required this.severity,
    required this.issueType,
    required this.location,
    required this.affectedArea,
    required this.isPublic,
    this.thumbnailUrl,
    this.isVideo = false,
    required this.createdAt,
    required this.updatedAt,
  });
}
