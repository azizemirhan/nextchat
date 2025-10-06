import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_message.dart';
import '../models/chat_sesssion.dart';
import '../services/chat_service.dart';

part 'chat_provider.g.dart';

@immutable
class ChatState {
  final List<ChatSession> sessions;
  final List<ChatMessage> currentMessages;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.sessions = const [],
    this.currentMessages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatSession>? sessions,
    List<ChatMessage>? currentMessages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      currentMessages: currentMessages ?? this.currentMessages,
      isLoading: isLoading ?? this.isLoading,
      error: error, // error'ı null yapabilmek için ?? this.error kaldırıldı
    );
  }
}

@riverpod
class ChatNotifier extends _$ChatNotifier {
  late final ChatService _chatService;
  WebSocketChannel? _channel;

  @override
  ChatState build() {
    _chatService = ChatService();
    // Notifier dispose olduğunda WebSocket bağlantısını kapat
    ref.onDispose(() {
      _channel?.sink.close();
    });
    return const ChatState();
  }

  Future<void> loadSessions({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final sessions = await _chatService.getSessions();
      state = state.copyWith(sessions: sessions, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), sessions: [], isLoading: false);
    }
  }

  Future<void> loadMessages(String sessionId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final messages = await _chatService.getMessages(sessionId);
      state = state.copyWith(currentMessages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> sendMessage(String sessionId, String message) async {
    try {
      await _chatService.sendMessage(sessionId, message);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> connectToChannel(String sessionId) async {
    disconnect();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    const reverbAppKey = 'YOUR_REVERB_APP_KEY';
    const host = '10.0.2.2';
    const port = 8080;

    final uri = Uri.parse('ws://$host:$port/app/$reverbAppKey');

    _channel = IOWebSocketChannel.connect(uri);
    print('Reverb sunucusuna bağlanılıyor: $uri');

    _channel?.stream.listen(
          (rawData) {
        final decodedOuter = jsonDecode(rawData);
        final event = decodedOuter['event'];

        if (event == 'pusher:connection_established') {
          print('Reverb bağlantısı başarıyla kuruldu!');
          _subscribeToChannel(sessionId, token);
        } else if (event == 'new.message') {
          final channel = decodedOuter['channel'];
          if (channel == 'private-chat.$sessionId') {
            final messagePayload = jsonDecode(decodedOuter['data']);
            if (messagePayload.containsKey('message')) {
              final messageJson = messagePayload['message'];
              final newMessage = ChatMessage.fromJson(messageJson);

              if (!state.currentMessages.any((msg) => msg.id == newMessage.id)) {
                // State'i immutable (değişmez) şekilde güncelliyoruz.
                final updatedMessages = List<ChatMessage>.from(state.currentMessages)..add(newMessage);
                state = state.copyWith(currentMessages: updatedMessages);
              }
            }
          }
        }
      },
      onError: (error) {
        print('Reverb Hatası: $error');
        state = state.copyWith(error: 'Anlık bağlantı kurulamadı.');
      },
    );
  }

  void _subscribeToChannel(String sessionId, String? token) {
    _channel?.sink.add(jsonEncode({
      'event': 'pusher:subscribe',
      'data': {
        'channel': 'private-chat.$sessionId',
        'auth': {
          'headers': { 'Authorization': 'Bearer $token' },
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

  Future<void> deleteMessage(int messageId) async {
    try {
      await _chatService.deleteMessage(messageId);
      final updatedMessages = List<ChatMessage>.from(state.currentMessages)..removeWhere((m) => m.id == messageId);
      state = state.copyWith(currentMessages: updatedMessages);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteSession(int sessionId) async {
    try {
      await _chatService.deleteSession(sessionId);
      final updatedSessions = List<ChatSession>.from(state.sessions)..removeWhere((s) => s.id == sessionId);
      state = state.copyWith(sessions: updatedSessions);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}