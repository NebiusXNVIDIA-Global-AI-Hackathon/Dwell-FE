import 'case_stage.dart';

enum ChatKind { caseChat, general }

/// 채팅 목록 타일 1개
class ChatThread {
  final String id;
  final ChatKind kind;

  /// "Water Leak · C-006" / "집주인이 연락을 안 받아요"
  final String title;

  /// "Deaver: …" 접두사 포함
  final String preview;

  /// "2m" / "Sep 30"
  final String timeLabel;
  final bool hasUnread;

  // caseChat 전용 — 타일은 썸네일만 쓰고 나머지는 채팅 헤더용
  final String? caseNo;
  final String? caseTitle;
  final String? caseLocation;
  final CaseStage? caseStage;
  final String? thumbnailPath;

  const ChatThread({
    required this.id,
    required this.kind,
    required this.title,
    required this.preview,
    required this.timeLabel,
    this.hasUnread = false,
    this.caseNo,
    this.caseTitle,
    this.caseLocation,
    this.caseStage,
    this.thumbnailPath,
  });

  ChatThread copyWith({
    String? title,
    String? preview,
    String? timeLabel,
    bool? hasUnread,
    CaseStage? caseStage,
  }) {
    return ChatThread(
      id: id,
      kind: kind,
      title: title ?? this.title,
      preview: preview ?? this.preview,
      timeLabel: timeLabel ?? this.timeLabel,
      hasUnread: hasUnread ?? this.hasUnread,
      caseNo: caseNo,
      caseTitle: caseTitle,
      caseLocation: caseLocation,
      caseStage: caseStage ?? this.caseStage,
      thumbnailPath: thumbnailPath,
    );
  }
}
