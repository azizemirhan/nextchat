import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'dart:convert';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post('/login', body: {
      'email': email,
      'password': password,
    });

    final token = response['token'];
    final user = User.fromJson(response['user']);

    await _saveAuthData(token, user);
    ApiService.setToken(token);

    // FCM token gönder
    await _sendFcmToken();

    return {'token': token, 'user': user};
  }

  Future<void> logout() async {
    try {
      await ApiService.post('/logout', needsAuth: true);
    } catch (e) {
      // Ignore
    }
    await _clearAuthData();
    ApiService.clearToken();
  }

  Future<User?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    final token = prefs.getString(_tokenKey);

    if (userJson != null && token != null) {
      ApiService.setToken(token);
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<void> _sendFcmToken() async {
    try {
      final fcmToken = await NotificationService.getFcmToken();
      if (fcmToken != null) {
        await ApiService.post(
          '/user/fcm-token',
          body: {'fcm_token': fcmToken},
          needsAuth: true,
        );
      }
    } catch (e) {
      print('FCM token error: $e');
    }
  }

  Future<void> _saveAuthData(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    // HATA BU SATIRDA MEYDANA GELİYOR:
    await prefs.setString(_userKey, jsonEncode(user));
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}