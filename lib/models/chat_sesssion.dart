import 'chat_message.dart';

class ChatSession {
  final int id;
  final String sessionId;
  final String? visitorName;
  final String? visitorEmail;
  final String status;
  final DateTime lastActivity;
  final int unreadCount;
  final ChatMessage? lastMessage;

  ChatSession({
    required this.id,
    required this.sessionId,
    this.visitorName,
    this.visitorEmail,
    required this.status,
    required this.lastActivity,
    this.unreadCount = 0,
    this.lastMessage,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      sessionId: json['session_id'],
      visitorName: json['visitor_name'],
      visitorEmail: json['visitor_email'],
      status: json['status'],
      lastActivity: DateTime.parse(json['last_activity']),
      unreadCount: json['unread_visitor_messages_count'] ?? 0,
      lastMessage: json['messages'] != null && (json['messages'] as List).isNotEmpty
          ? ChatMessage.fromJson(json['messages'][0])
          : null,
    );
  }
}