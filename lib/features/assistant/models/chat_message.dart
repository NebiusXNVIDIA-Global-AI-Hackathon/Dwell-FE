import 'info_card.dart';

enum MessageType { deaver, user, system, image, typing }

/// 채팅 버블 1개
class ChatMessage {
  final MessageType type;
  final String text;

  /// type == image
  final String? imagePath;

  /// 버블 안 카드
  final InfoCard? card;

  /// 버블 안 흰 카드 — 통지문·답장 초안
  final String? draftText;

  /// "Sent via Messages · 3:12 PM"
  final String? sentVia;

  const ChatMessage({
    required this.type,
    this.text = '',
    this.imagePath,
    this.card,
    this.draftText,
    this.sentVia,
  });

  const ChatMessage.deaver(this.text, {this.card, this.draftText})
    : type = MessageType.deaver,
      imagePath = null,
      sentVia = null;

  const ChatMessage.user(this.text, {this.sentVia})
    : type = MessageType.user,
      imagePath = null,
      card = null,
      draftText = null;

  /// "Case C-006 updated: X → Y" · "Today 9:12 AM" 구분선
  const ChatMessage.system(this.text)
    : type = MessageType.system,
      imagePath = null,
      card = null,
      draftText = null,
      sentVia = null;

  const ChatMessage.image(this.imagePath, {this.text = ''})
    : type = MessageType.image,
      card = null,
      draftText = null,
      sentVia = null;

  const ChatMessage.typing()
    : type = MessageType.typing,
      text = '',
      imagePath = null,
      card = null,
      draftText = null,
      sentVia = null;
}
