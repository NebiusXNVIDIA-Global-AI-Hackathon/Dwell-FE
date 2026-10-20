import 'issue_category.dart';
import 'localized_text.dart';
import 'neighbor_post.dart';

/// 시그널 목록 한 줄 — Rising Issue 카드
class BuildingSignal {
  final int signalId;
  final IssueCategory category;
  final String title;

  /// 카드가 좁을 때 쓰는 짧은 이름
  final String issueLabel;
  final String description;

  /// 앱 공개 케이스 + HPD 기록 합계
  final int reportCount;

  const BuildingSignal({
    required this.signalId,
    required this.category,
    required this.title,
    required this.issueLabel,
    required this.description,
    required this.reportCount,
  });
}

/// 내 케이스와 같은 이슈 중 가장 강한 패턴
class PrimarySignal {
  final int signalId;
  final IssueCategory category;
  final String title;
  final String issueLabel;
  final int reportCount;

  /// 신고된 위치 — 없으면 빈 목록
  final List<String> reportedIn;

  /// 집계 기간 문구
  final String windowLabel;
  final bool relatedToMyCase;

  const PrimarySignal({
    required this.signalId,
    required this.category,
    required this.title,
    required this.issueLabel,
    required this.reportCount,
    required this.windowLabel,
    this.reportedIn = const [],
    this.relatedToMyCase = false,
  });
}

/// Building Signals 목록 화면
class BuildingSignals {
  /// 없으면 null
  final PrimarySignal? primary;
  final List<BuildingSignal> risingIssues;

  const BuildingSignals({this.primary, required this.risingIssues});
}

/// 시그널 상세 — 이슈 하나에 달린 이웃 글 모음
class SignalDetail {
  final int signalId;
  final IssueCategory category;
  final String title;
  final bool relatedToMyCase;

  /// Deaver's insight — 번역 포함, 없으면 null
  final LocalizedText? insight;
  final List<NeighborPost> posts;

  const SignalDetail({
    required this.signalId,
    required this.category,
    required this.title,
    required this.posts,
    this.insight,
    this.relatedToMyCase = false,
  });
}
