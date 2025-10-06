import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/chat_sesssion.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';

// StatefulWidget'ı ConsumerStatefulWidget'a çeviriyoruz.
class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  @override
  void initState() {
    super.initState();
    // initState içinde `ref.read` kullanarak provider'ı bir kerelik çağırabiliriz.
    // Bu, ekran ilk açıldığında sohbet oturumlarını yükler.
    Future.microtask(() => ref.read(chatProvider.notifier).loadSessions());
  }

  @override
  Widget build(BuildContext context) {
    // `ref.watch` ile ChatProvider'daki değişiklikleri dinliyoruz.
    final chatState = ref.watch(chatProvider);
    final sessions = chatState.sessions;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: const Text('Aktif Sohbetler', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2d2d2d),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (String value) async {
              if (value == 'logout') {
                // `ref.read` ile AuthNotifier'daki logout metodunu çağırıyoruz.
                await ref.read(authNotifierProvider.notifier).logout();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Çıkış Yap'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(chatProvider.notifier).loadSessions(),
        child: chatState.isLoading && sessions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : sessions.isEmpty
            ? Center(
          child: Text(
            'Aktif Chat Yok',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
          ),
        )
            : ListView.builder(
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return Card(
              color: const Color(0xFF2d2d2d),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFF8C00),
                  child: Text(
                    session.visitorName?.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  session.visitorName ?? 'Bilinmeyen Ziyaretçi',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Son Mesaj: ${DateFormat('dd MMM, HH:mm').format(session.lastActivity ?? session.createdAt)}',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(session: session),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}