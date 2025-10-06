import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'dart:convert';

class AuthService {
  // Yeni ApiService'ten bir örnek oluşturuyoruz.
  final ApiService _apiService = ApiService();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Metodun dönüş tipini ve içeriğini güncelledik.
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Artık _apiService örneği üzerinden post metodunu çağırıyoruz.
      final response = await _apiService.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final user = User.fromJson(response.data['user']);

        await _saveAuthData(token, user);

        // FCM token'ı gönder
        await _sendFcmToken();

        return {'token': token, 'user': user};
      } else {
        // ApiService içindeki hata yönetimi zaten bir exception fırlatacak,
        // ama yine de bir güvence olarak ekleyelim.
        throw 'Giriş başarısız oldu.';
      }
    } catch (e) {
      // Hataları tekrar fırlatarak UI katmanının yakalamasını sağlıyoruz.
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      // Artık static değil, örnek üzerinden çağırıyoruz.
      // Token otomatik eklendiği için header belirtmeye gerek yok.
      await _apiService.post('/logout');
    } catch (e) {
      // Sunucuya ulaşılamasa bile çıkış yapabilmeli, o yüzden hatayı yoksay.
      print('Logout error: $e');
    }
    await _clearAuthData();
  }

  Future<User?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    final token = prefs.getString(_tokenKey);

    if (userJson != null && token != null) {
      // Token'ı burada set etmeye gerek yok, interceptor her istekte bunu yapacak.
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<void> _sendFcmToken() async {
    try {
      final fcmToken = await NotificationService.getFcmToken();
      if (fcmToken != null) {
        // 'body' yerine 'data' parametresini kullanıyoruz.
        await _apiService.post(
          '/user/fcm-token',
          data: {'fcm_token': fcmToken},
        );
      }
    } catch (e) {
      print('FCM token gönderme hatası: $e');
    }
  }

  Future<void> _saveAuthData(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    // User modeline eklediğimiz toJson metodu sayesinde bu satır artık çalışacak.
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }


}