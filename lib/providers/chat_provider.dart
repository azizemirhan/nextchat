import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/chat_sesssion.dart';
import '../services/chat_service.dart';
import 'dart:async';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatSession> _sessions = [];
  List<ChatMessage> _currentMessages = [];
  bool _isLoading = false;
  String? _error; // Hata mesajı için değişken ekleyelim
  Timer? _pollingTimer;

  List<ChatSession> get sessions => _sessions;
  List<ChatMessage> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;
  String? get error => _error; // Hata mesajını dışarıya açalım

  Future<void> loadSessions({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    _error = null; // Her yeni istekte hatayı temizle

    try {
      _sessions = await _chatService.getSessions();
    } catch (e) {
      print('Load sessions error: $e');
      _error = e.toString(); // Hata mesajını yakala
      _sessions = []; // Hata durumunda listeyi boşalt
    }

    if (!silent) {
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> loadMessages(String sessionId) async {
    try {
      _currentMessages = await _chatService.getSessionMessages(sessionId);
      notifyListeners();
    } catch (e) {
      print('Load messages error: $e');
    }
  }

  Future<void> sendMessage(String sessionId, String message) async {
    try {
      final newMessage = await _chatService.sendMessage(sessionId, message);
      _currentMessages.add(newMessage);
      notifyListeners();
    } catch (e) {
      print('Send message error: $e');
    }
  }

  Future<bool> deleteMessage(int messageId) async {
    try {
      await _chatService.deleteMessage(messageId);
      _currentMessages.removeWhere((m) => m.id == messageId);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteSession(int sessionId) async {
    try {
      await _chatService.deleteSession(sessionId);
      _sessions.removeWhere((s) => s.id == sessionId);
      notifyListeners();
    } catch (e) {
      print('Delete session error: $e');
    }
  }

  void startPolling(String sessionId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      loadMessages(sessionId);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}