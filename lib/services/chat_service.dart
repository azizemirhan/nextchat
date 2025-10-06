import '../models/chat_message.dart';
import '../models/chat_sesssion.dart';
import 'api_service.dart';

class ChatService {
  final ApiService _apiService = ApiService();

  Future<List<ChatSession>> getSessions() async {
    try {
      // DÜZELTME: Adresin başına '/chat' eklendi.
      final response = await _apiService.get('/chat/sessions');
      if (response.statusCode == 200) {
        // API'den gelen yanıtın yapısına göre 'sessions' anahtarını kullanıyoruz.
        List<dynamic> data = response.data['sessions'];
        return data.map((json) => ChatSession.fromJson(json)).toList();
      }
      throw 'Oturumlar alınamadı.';
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ChatMessage>> getMessages(String sessionId) async {
    try {
      // DÜZELTME: Adresin başına '/chat' eklendi.
      final response = await _apiService.get('/chat/sessions/$sessionId');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data['messages'];
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      }
      throw 'Mesajlar alınamadı.';
    } catch (e) {
      rethrow;
    }
  }

  Future<ChatMessage> sendMessage(String sessionId, String message) async {
    try {
      // DÜZELTME: Adresin başına '/chat' eklendi.
      final response = await _apiService.post(
        '/chat/sessions/$sessionId/send',
        data: {'message': message},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ChatMessage.fromJson(response.data['data']);
      }
      throw 'Mesaj gönderilemedi.';
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMessage(int messageId) async {
    try {
      // DÜZELTME: Adresin başına '/chat' eklendi.
      await _apiService.delete('/chat/messages/$messageId');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSession(int sessionId) async {
    try {
      // DÜZELTME: Adresin başına '/chat' eklendi.
      await _apiService.delete('/chat/sessions/$sessionId');
    } catch (e) {
      rethrow;
    }
  }
}