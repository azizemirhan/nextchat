import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

// Bu satır, build_runner'ın "auth_provider.g.dart" dosyasını oluşturmasını sağlar.
part 'auth_provider.g.dart';

// @riverpod anotasyonu ile kod üreticisini tetikliyoruz.
@riverpod
class AuthNotifier extends _$AuthNotifier {
  late final AuthService _authService;

  // build metodu, provider ilk oluşturulduğunda çalışır.
  // Kullanıcının mevcut giriş durumunu kontrol eder.
  @override
  Future<User?> build() async {
    _authService = AuthService();
    // state'i (durumu) başlangıçta null olarak ayarlıyoruz.
    state = const AsyncValue.loading();
    return await _authService.getStoredUser();
  }

  // Login metodu
  Future<void> login(String email, String password) async {
    // UI'ın yükleniyor durumuna geçtiğini bildir.
    state = const AsyncValue.loading();
    try {
      // Giriş yap ve dönen user nesnesini state'e ata.
      final result = await _authService.login(email, password);
      state = AsyncValue.data(result['user']);
    } catch (e) {
      // Hata durumunda state'i güncelle.
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Logout metodu
  Future<void> logout() async {
    await _authService.logout();
    // Çıkış yapıldığında kullanıcı durumunu null yap.
    state = const AsyncValue.data(null);
  }
}