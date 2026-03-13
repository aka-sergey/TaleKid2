import 'package:dio/dio.dart';

import 'api_client.dart';

/// Auth API service
class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _client.dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          if (displayName != null) 'display_name': displayName,
        },
      );

      final data = response.data as Map<String, dynamic>;

      // Save tokens
      await _client.saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
      );

      return data;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;

      // Save tokens
      await _client.saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
      );

      return data;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _client.dio.get('/auth/me');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// Logout (clear tokens)
  Future<void> logout() async {
    await _client.clearTokens();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _client.hasTokens();
  }
}
