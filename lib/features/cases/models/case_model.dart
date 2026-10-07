enum CaseStatus { active, logged, resolved }

enum CaseSeverity { low, medium, high }

enum CaseMediaType { image, video, audio }

class CaseEvidence {
  final String id;
  final CaseMediaType mediaType;
  final DateTime uploadedAt;

  // 사진 이미지 또는 영상의 미리보기 이미지
  final String? thumbnailUrl;

  const CaseEvidence({
    required this.id,
    required this.mediaType,
    required this.uploadedAt,
    this.thumbnailUrl,
  });
}

class CaseModel {
  final String id;
  final String title;
  final CaseStatus status;
  final CaseSeverity severity;
  final String issueType;
  final String location;
  final String affectedArea;
  final bool isPublic;
  final List<CaseEvidence> evidenceList;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CaseModel({
    required this.id,
    required this.title,
    required this.status,
    required this.severity,
    required this.issueType,
    required this.location,
    required this.affectedArea,
    required this.isPublic,
    this.evidenceList = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // 목록 순서와 관계없이 가장 먼저 업로드한 증거 반환
  CaseEvidence? get representativeEvidence {
    if (evidenceList.isEmpty) {
      return null;
    }

    var earliest = evidenceList.first;

    for (final evidence in evidenceList.skip(1)) {
      if (evidence.uploadedAt.isBefore(earliest.uploadedAt)) {
        earliest = evidence;
      }
    }

    return earliest;
  }
}
