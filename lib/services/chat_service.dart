import '../models/chat_message.dart';
import '../models/chat_sesssion.dart';
import 'api_service.dart';

class ChatService {
  Future<List<ChatSession>> getSessions() async {
    final response = await ApiService.get('/chat/sessions', needsAuth: true);
    return (response['sessions'] as List)
        .map((json) => ChatSession.fromJson(json))
        .toList();
  }

  Future<List<ChatMessage>> getSessionMessages(String sessionId) async {
    final response = await ApiService.get(
      '/chat/sessions/$sessionId',
      needsAuth: true,
    );
    return (response['messages'] as List)
        .map((json) => ChatMessage.fromJson(json))
        .toList();
  }

  Future<ChatMessage> sendMessage(String sessionId, String message) async {
    final response = await ApiService.post(
      '/chat/sessions/$sessionId/send',
      body: {'message': message},
      needsAuth: true,
    );
    return ChatMessage.fromJson(response['data']);
  }

  Future<void> deleteSession(int sessionId) async {
    await ApiService.delete('/chat/sessions/$sessionId', needsAuth: true);
  }

  Future<void> deleteMessage(int messageId) async {
    await ApiService.delete('/messages/$messageId', needsAuth: true);
  }
}