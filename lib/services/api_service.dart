import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static String? _token;

  static void setToken(String token) => _token = token;
  static void clearToken() => _token = null;

  static Map<String, String> _headers({bool needsAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (needsAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> post(String endpoint, {
    Map<String, dynamic>? body,
    bool needsAuth = false,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: _headers(needsAuth: needsAuth),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 10));

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> get(String endpoint, {
    bool needsAuth = false,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: _headers(needsAuth: needsAuth),
    ).timeout(const Duration(seconds: 10));

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(String endpoint, {
    bool needsAuth = false,
  }) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: _headers(needsAuth: needsAuth),
    ).timeout(const Duration(seconds: 10));

    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw Exception(data['message'] ?? 'An error occurred');
  }
}