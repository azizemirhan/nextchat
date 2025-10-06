import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/chat_sesssion.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  final ChatSession session;

  const ChatScreen({Key? key, required this.session}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
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
      final provider = context.read<ChatProvider>();

      // 1. Sayfa açıldığında mevcut mesajları bir kere yükle
      provider.loadMessages(widget.session.sessionId);

      // 2. Polling yerine WebSocket bağlantısını başlat
      provider.connectToChannel(widget.session.sessionId);

      _fabController?.forward();
    });
  }

  @override
  void dispose() {
    // 3. Sayfa kapandığında WebSocket bağlantısını güvenli bir şekilde kes
    context.read<ChatProvider>().disconnect();

    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _fabController?.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text;
    _messageController.clear();

    await context.read<ChatProvider>().sendMessage(widget.session.sessionId, text);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
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
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFFF8C00).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8C00).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFF8C00)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF8C00).withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.session.visitorName?.substring(0, 1).toUpperCase() ?? '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.session.visitorName ?? 'Chat',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            widget.session.visitorEmail ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Messages
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, provider, _) {
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                    if (provider.isLoading && provider.currentMessages.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (provider.currentMessages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade700),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz mesaj yok',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Konuşmayı başlatın',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.currentMessages.length,
                      itemBuilder: (context, index) {
                        final msg = provider.currentMessages[index];
                        final isAdmin = msg.isFromAdmin;
                        final showDate = index == 0 ||
                            !_isSameDay(
                              msg.createdAt,
                              provider.currentMessages[index - 1].createdAt,
                            );

                        return Column(
                          children: [
                            if (showDate)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2d2d2d),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _formatDate(msg.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            Align(
                              alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                              child: GestureDetector(
                                onLongPress: isAdmin
                                    ? () async {
                                  final result = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Mesajı Sil'),
                                      content: const Text('Bu mesajı silmek istediğinizden emin misiniz?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('İptal'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Sil', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (result == true) {
                                    await provider.deleteMessage(msg.id);
                                  }
                                }
                                    : null,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isAdmin
                                        ? const LinearGradient(
                                      colors: [
                                        Color(0xFFFF8C00),
                                        Color(0xFFFF6B00),
                                      ],
                                    )
                                        : null,
                                    color: isAdmin ? null : const Color(0xFF2d2d2d),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft: Radius.circular(isAdmin ? 20 : 4),
                                      bottomRight: Radius.circular(isAdmin ? 4 : 20),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isAdmin
                                            ? const Color(0xFFFF8C00).withOpacity(0.3)
                                            : Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg.message,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: isAdmin ? Colors.white : Colors.grey.shade300,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        DateFormat('HH:mm').format(msg.createdAt),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isAdmin
                                              ? Colors.white.withOpacity(0.8)
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              // Input area
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2d2d2d),
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFFFF8C00).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF3d3d3d),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFFF8C00).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Mesajınızı Yazın...',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ScaleTransition(
                      scale: _fabController != null
                          ? Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(parent: _fabController!, curve: Curves.elasticOut),
                      )
                          : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF8C00).withOpacity(0.6),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white),
                          onPressed: _sendMessage,
                          iconSize: 24,
                        ),
                      ),
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