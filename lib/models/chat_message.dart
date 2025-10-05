class ChatMessage {
  final int id;
  final int chatSessionId;
  final String senderType;
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.chatSessionId,
    required this.senderType,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      chatSessionId: json['chat_session_id'],
      senderType: json['sender_type'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isFromVisitor => senderType == 'visitor';
  bool get isFromAdmin => senderType == 'admin';
}