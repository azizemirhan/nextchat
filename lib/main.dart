import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // EKLENDİ
import 'package:firebase_core/firebase_core.dart';
// provider paketini artık burada kullanmayacağız.
// import 'package:provider/provider.dart';
// import 'providers/auth_provider.dart';
// import 'providers/chat_provider.dart';
import 'screens/login_screen.dart';
import 'screens/sessions_screen.dart';
import 'services/notification_service.dart';

// Riverpod sağlayıcılarımızı bu dosyadan çağıracağız.
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Init error: $e');
  }

  // runApp'i ProviderScope ile sarmalıyoruz.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // MultiProvider'ı tamamen kaldırıyoruz.
    return MaterialApp(
      title: 'Admin Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthChecker(), // SplashScreen yerine yeni bir kontrol widget'ı
      debugShowCheckedModeBanner: false,
    );
  }
}

// YENİ WIDGET: AuthChecker
// Bu widget, kullanıcının giriş durumunu dinler ve doğru ekrana yönlendirir.
class AuthChecker extends ConsumerWidget {
  const AuthChecker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // authNotifierProvider'ı dinliyoruz.
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      data: (user) {
        // Veri geldiğinde (kullanıcı null olabilir veya olmayabilir)
        if (user != null) {
          return const SessionsScreen();
        }
        return const LoginScreen();
      },
      loading: () {
        // Yükleniyor durumunda
        return const SplashScreen();
      },
      error: (error, stackTrace) {
        // Hata durumunda (örneğin internet yoksa)
        // Güvenli bir başlangıç için LoginScreen'e yönlendirebiliriz.
        return const LoginScreen();
      },
    );
  }
}


// ESKİ SplashScreen'i şimdilik basit bir yükleme ekranı olarak tutalım.
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}