import 'dart:convert'; // jsonDecode ve jsonEncode için eklendi
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences için eklendi
import 'package:web_socket_channel/io.dart'; // IOWebSocketChannel için eklendi
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_message.dart';
import '../models/chat_sesssion.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatSession> _sessions = [];
  List<ChatMessage> _currentMessages = [];
  bool _isLoading = false;
  String? _error;

  WebSocketChannel? _channel;

  List<ChatSession> get sessions => _sessions;
  List<ChatMessage> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSessions({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    _error = null;

    try {
      _sessions = await _chatService.getSessions();
    } catch (e) {
      _error = e.toString();
      _sessions = [];
    }

    if (!silent) {
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> loadMessages(String sessionId) async {
    try {
      _currentMessages = await _chatService.getMessages(sessionId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendMessage(String sessionId, String message) async {
    try {
      // Sadece gönderme işlemini yapıyoruz, dönen cevabı beklemiyoruz.
      // Çünkü mesaj bize anlık olarak WebSocket üzerinden gelecek.
      await _chatService.sendMessage(sessionId, message);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> connectToChannel(String sessionId) async {
    disconnect();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // --- REVERB İÇİN GÜNCELLENEN KISIM ---
    // Laravel .env dosyanızdaki REVERB_* değişkenlerini kullanın.
    const reverbAppKey = 'jnsom1flpeouh2ksikzz'; // .env dosyanızdaki REVERB_APP_KEY
    const host = '10.0.2.2'; // Android emülatör için. Gerçek cihazda API IP adresiniz.
    const port = 8080;       // Reverb'in varsayılan portu.

    final uri = Uri.parse('ws://$host:$port/app/$reverbAppKey');
    // ------------------------------------

    _channel = IOWebSocketChannel.connect(uri);
    print('Reverb sunucusuna bağlanılıyor: $uri');

    _channel?.stream.listen(
          (data) {
        final decoded = jsonDecode(data);
        final event = decoded['event'];

        if (event == 'pusher:connection_established') {
          print('Reverb bağlantısı başarıyla kuruldu!');
          _subscribeToChannel(sessionId, token);
        } else if (event == 'new.message') {
          final channel = decoded['channel'];
          if (channel == 'private-chat.$sessionId') {
            final messageData = jsonDecode(decoded['data'])['message'];
            final newMessage = ChatMessage.fromJson(messageData);

            if (!_currentMessages.any((msg) => msg.id == newMessage.id)) {
              _currentMessages.add(newMessage);
              notifyListeners();
            }
          }
        }
      },
      onError: (error) {
        print('Reverb Hatası: $error');
        _error = 'Anlık bağlantı kurulamadı.';
        notifyListeners();
      },
      onDone: () {
        print('Reverb bağlantısı kapandı.');
      },
    );
  }

  void _subscribeToChannel(String sessionId, String? token) {
    _channel?.sink.add(jsonEncode({
      'event': 'pusher:subscribe',
      'data': {
        'channel': 'private-chat.$sessionId',
        'auth': {
          'headers': {
            'Authorization': 'Bearer $token',
          },
        },
      },
    }));
    print('"$sessionId" kanalına abonelik isteği gönderildi.');
  }

  void disconnect() {
    if (_channel != null) {
      _channel?.sink.close();
      _channel = null;
      print('Reverb bağlantısı kesildi.');
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }

  Future<bool> deleteMessage(int messageId) async {
    try {
      await _chatService.deleteMessage(messageId);
      _currentMessages.removeWhere((m) => m.id == messageId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteSession(int sessionId) async {
    try {
      await _chatService.deleteSession(sessionId);
      _sessions.removeWhere((s) => s.id == sessionId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}