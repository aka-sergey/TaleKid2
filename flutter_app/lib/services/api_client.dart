import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';

/// HTTP client with JWT authentication interceptor
class ApiClient {
  late final Dio dio;
  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  ApiClient({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(_AuthInterceptor(this));
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[API] $obj'),
    ));
  }

  // Token management
  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Attempt to refresh the access token
  Future<bool> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    try {
      // Use a separate Dio instance to avoid interceptor loop
      final refreshDio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        headers: {'Content-Type': 'application/json'},
      ));

      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        await saveTokens(
          accessToken: response.data['access_token'],
          refreshToken: response.data['refresh_token'],
        );
        return true;
      }
    } catch (e) {
      // Refresh failed - user needs to re-login
      await clearTokens();
    }
    return false;
  }
}

/// JWT Auth Interceptor - adds token to requests and handles 401
class _AuthInterceptor extends Interceptor {
  final ApiClient _client;
  bool _isRefreshing = false;

  _AuthInterceptor(this._client);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for public endpoints
    final publicPaths = ['/auth/login', '/auth/register', '/auth/refresh', '/health', '/catalog'];
    final isPublic = publicPaths.any((p) => options.path.startsWith(p));

    if (!isPublic) {
      final token = await _client.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        final refreshed = await _client.refreshAccessToken();
        if (refreshed) {
          // Retry the original request with new token
          final token = await _client.getAccessToken();
          err.requestOptions.headers['Authorization'] = 'Bearer $token';

          final response = await _client.dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        }
      } finally {
        _isRefreshing = false;
      }
    }

    handler.next(err);
  }
}

/// API Error class
class ApiError {
  final int? statusCode;
  final String message;
  final dynamic data;

  ApiError({
    this.statusCode,
    required this.message,
    this.data,
  });

  factory ApiError.fromDioException(DioException e) {
    String message;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Время ожидания истекло. Проверьте подключение к интернету.';
        break;
      case DioExceptionType.connectionError:
        message = 'Не удалось подключиться к серверу.';
        break;
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        if (data is Map && data.containsKey('detail')) {
          message = data['detail'].toString();
        } else {
          message = 'Ошибка сервера (${e.response?.statusCode})';
        }
        break;
      default:
        message = 'Произошла неизвестная ошибка.';
    }

    return ApiError(
      statusCode: e.response?.statusCode,
      message: message,
      data: e.response?.data,
    );
  }

  @override
  String toString() => 'ApiError($statusCode): $message';
}
