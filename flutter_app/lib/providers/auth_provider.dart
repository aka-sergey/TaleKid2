import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

/// User model for auth state
class AuthUser {
  final String id;
  final String email;
  final String? displayName;

  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
    );
  }
}

/// Singleton API client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthService(client);
});

/// Auth state - null means not logged in, AuthUser means logged in
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthUser?>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    // Check if user has saved tokens
    final authService = ref.read(authServiceProvider);
    final isLoggedIn = await authService.isLoggedIn();

    if (isLoggedIn) {
      try {
        final profile = await authService.getProfile();
        return AuthUser.fromJson(profile);
      } catch (_) {
        // Token expired or invalid
        await authService.logout();
        return null;
      }
    }
    return null;
  }

  /// Register a new user
  Future<void> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      final profile = await authService.getProfile();
      return AuthUser.fromJson(profile);
    });
  }

  /// Login with email and password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.login(email: email, password: password);
      final profile = await authService.getProfile();
      return AuthUser.fromJson(profile);
    });
  }

  /// Logout
  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    state = const AsyncData(null);
  }
}
