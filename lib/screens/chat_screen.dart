import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/chat_sesssion.dart';
import '../providers/chat_provider.dart';

// StatefulWidget'ı ConsumerStatefulWidget'a çeviriyoruz
class ChatScreen extends ConsumerStatefulWidget {
  final ChatSession session;

  const ChatScreen({Key? key, required this.session}) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

// State sınıfını ConsumerState olarak güncelliyoruz
class _ChatScreenState extends ConsumerState<ChatScreen> with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  AnimationController? _fabController;

  @override
  void initState() {
    super.initState();

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(chatNotifierProvider.notifier);
      notifier.loadMessages(widget.session.sessionId);
      notifier.connectToChannel(widget.session.sessionId);
      _fabController?.forward();
    });
  }

  @override
  void dispose() {
    ref.read(chatNotifierProvider.notifier).disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _fabController?.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final text = _messageController.text;
    _messageController.clear();
    _focusNode.requestFocus();
    await ref.read(chatNotifierProvider.notifier).sendMessage(widget.session.sessionId, text);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final messages = chatState.currentMessages;

    _scrollToBottom();

    return Scaffold(
      body: Container(
        color: const Color(0xFF1a1a1a),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2d2d2d),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFF8C00)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      backgroundColor: const Color(0xFFFF8C00),
                      child: Text(
                        widget.session.visitorName?.substring(0, 1).toUpperCase() ?? '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.session.visitorName ?? 'Chat',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            widget.session.visitorEmail ?? '',
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Messages
              Expanded(
                child: chatState.isLoading && messages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : messages.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade700),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz mesaj yok',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isAdmin = msg.isFromAdmin;
                    final showDate = index == 0 || !_isSameDay(msg.createdAt, messages[index - 1].createdAt);

                    return Column(
                      children: [
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2d2d2d),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(_formatDate(msg.createdAt),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        Align(
                          alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                          child: GestureDetector(
                            // ----- DÜZELTİLEN KISIM BURASI -----
                            onLongPress: isAdmin ? () async {
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Mesajı Sil'),
                                  content: const Text('Bu mesajı silmek istediğinizden emin misiniz?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Sil', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );

                              if (result == true) {
                                // `provider.deleteMessage` yerine `ref.read` ile notifier'ı çağırıyoruz.
                                await ref.read(chatNotifierProvider.notifier).deleteMessage(msg.id);
                              }
                            } : null,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isAdmin ? const Color(0xFFFF8C00) : const Color(0xFF2d2d2d),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isAdmin ? 20 : 4),
                                  bottomRight: Radius.circular(isAdmin ? 4 : 20),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.message,
                                    style: TextStyle(fontSize: 15, color: isAdmin ? Colors.white : Colors.grey.shade300),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('HH:mm').format(msg.createdAt),
                                    style: TextStyle(fontSize: 11, color: isAdmin ? Colors.white.withOpacity(0.8) : Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Input area
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Mesajınızı Yazın...',
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          filled: true,
                          fillColor: const Color(0xFF2d2d2d),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: Color(0xFFFF8C00)),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) {
      return 'Bugün';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Dün';
    } else {
      return DateFormat('dd MMM, yyyy').format(date);
    }
  }
}