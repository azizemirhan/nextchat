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
  Timer? _pollingTimer;

  List<ChatSession> get sessions => _sessions;
  List<ChatMessage> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;

  Future<void> loadSessions({bool silent = false}) async {
    if (!silent) _isLoading = true;
    notifyListeners();

    try {
      _sessions = await _chatService.getSessions();
    } catch (e) {
      print('Load sessions error: $e');
    }

    if (!silent) _isLoading = false;
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