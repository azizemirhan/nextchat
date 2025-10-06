import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  final Dio _dio;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal()
      : _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(milliseconds: 15000),
    receiveTimeout: const Duration(milliseconds: 15000),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  )) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');

          // ----- YENİ EKLENEN LOGLAMA KODLARI -----
          print('--- API İsteği Gönderiliyor ---');
          print('URL: ${options.uri}');
          if (token != null) {
            print('Bulunan Token: Bearer $token');
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            print('HATA: SharedPreferences içinde token bulunamadı!');
          }
          print('---------------------------------');
          // ------------------------------------

          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Bu log zaten çalışıyor, o yüzden dokunmuyoruz.
          print('API Hatası: ${e.response?.statusCode} - ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    String errorMessage = 'Bir hata oluştu.';
    if (e.response != null && e.response?.data is Map) {
      if (e.response?.data.containsKey('message')) {
        errorMessage = e.response?.data['message'];
      }
    } else {
      errorMessage = 'Lütfen internet bağlantınızı kontrol edin.';
    }
    return errorMessage;
  }
}