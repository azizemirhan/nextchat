import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({Key? key}) : super(key: key);

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> with SingleTickerProviderStateMixin {
  Timer? _sessionsTimer;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChatProvider>();
      provider.loadSessions();
      _animationController.forward();

      _sessionsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        provider.loadSessions(silent: true);
      });
    });
  }

  @override
  void dispose() {
    _sessionsTimer?.cancel();
    _animationController.dispose();
    super.dispose();
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Müşterilerim',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Müşteriler ile konuşmalar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8C00).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFF8C00)),
                        onPressed: () {
                          context.read<ChatProvider>().loadSessions();
                          _animationController.reset();
                          _animationController.forward();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      offset: const Offset(0, 50),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF8C00).withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 24),
                      ),
                      itemBuilder: (BuildContext context) {
                        final authProvider = context.read<AuthProvider>();
                        return <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            enabled: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authProvider.user?.name ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  authProvider.user?.email ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem<String>(
                            value: 'Çıkış Yap',
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: Colors.red.shade400, size: 20),
                                const SizedBox(width: 12),
                                const Text('Çıkış Yap'),
                              ],
                            ),
                          ),
                        ];
                      },
                      onSelected: (String value) async {
                        if (value == 'logout') {
                          await context.read<AuthProvider>().logout();
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Sessions list
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, _) {
                    if (chatProvider.isLoading) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2d2d2d),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF8C00).withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8C00)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Mesajlar Yükleniyor...',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (chatProvider.error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'An error occurred:\n${chatProvider.error}',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (chatProvider.sessions.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: () => chatProvider.loadSessions(),
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade700),
                                const SizedBox(height: 24),
                                Text(
                                  'Aktif Chat Yok',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sitenizden Gelen Mesaj Yok',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => chatProvider.loadSessions(),
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: chatProvider.sessions.length,
                            itemBuilder: (context, index) {
                              final session = chatProvider.sessions[index];
                              final timeFormat = DateFormat('HH:mm');
                              final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: _animationController,
                                  curve: Interval(
                                    (index / chatProvider.sessions.length) * 0.5,
                                    ((index + 1) / chatProvider.sessions.length) * 0.5 + 0.5,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                              );

                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.3, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: Dismissible(
                                    key: Key(session.sessionId),
                                    direction: DismissDirection.endToStart,
                                    onDismissed: (direction) {
                                      context.read<ChatProvider>().deleteSession(session.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.check_circle, color: Colors.white),
                                              const SizedBox(width: 12),
                                              Text('${session.visitorName ?? "Chat"} Silindi'),
                                            ],
                                          ),
                                          backgroundColor: Colors.green.shade600,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          margin: const EdgeInsets.all(16),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    background: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.delete_outline, color: Colors.white, size: 32),
                                          SizedBox(height: 4),
                                          Text(
                                            'Sil',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2d2d2d),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFFFF8C00).withOpacity(0.3),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFF8C00).withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ChatScreen(session: session),
                                              ),
                                            ).then((_) {
                                              context.read<ChatProvider>().loadSessions(silent: true);
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 56,
                                                  height: 56,
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [
                                                        Color(0xFFFF8C00),
                                                        Color(0xFFFF6B00),
                                                      ],
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
                                                      session.visitorName?.substring(0, 1).toUpperCase() ?? '?',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              session.visitorName ?? 'Anonymous',
                                                              style: const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                                                color: Color(0xFFFF8C00),
                                                              ),
                                                            ),
                                                          ),
                                                          Text(
                                                            timeFormat.format(session.lastActivity),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey.shade500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              session.lastMessage?.message ?? '',
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: Colors.grey.shade500,
                                                              ),
                                                            ),
                                                          ),
                                                          if (session.unreadCount > 0)
                                                            Container(
                                                              margin: const EdgeInsets.only(left: 8),
                                                              padding: const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                              decoration: BoxDecoration(
                                                                gradient: const LinearGradient(
                                                                  colors: [
                                                                    Color(0xFFFF8C00),
                                                                    Color(0xFFFF6B00),
                                                                  ],
                                                                ),
                                                                borderRadius: BorderRadius.circular(12),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: const Color(0xFFFF8C00).withOpacity(0.4),
                                                                    blurRadius: 8,
                                                                    offset: const Offset(0, 2),
                                                                  ),
                                                                ],
                                                              ),
                                                              child: Text(
                                                                '${session.unreadCount}',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}