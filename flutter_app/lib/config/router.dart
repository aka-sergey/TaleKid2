import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/landing/landing_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/wizard/wizard_screen.dart';
import '../screens/generation/generation_progress_screen.dart';
import '../screens/reader/reader_screen.dart';
import '../screens/library/library_screen.dart';

/// Application route paths
class AppRoutes {
  static const String landing = '/';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String home = '/home';
  static const String wizard = '/wizard';
  static const String generationProgress = '/wizard/progress/:jobId';
  static const String storyReader = '/stories/:id';
  static const String library = '/library';
  static const String terms = '/terms';
  static const String privacy = '/privacy';
  static const String consent = '/consent';
}

/// GoRouter provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.landing,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.valueOrNull != null;
      final currentPath = state.matchedLocation;

      // Public routes that don't require auth
      const publicRoutes = [
        AppRoutes.landing,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.terms,
        AppRoutes.privacy,
        AppRoutes.consent,
      ];

      final isPublicRoute = publicRoutes.contains(currentPath);

      // Not logged in and trying to access protected route
      if (!isLoggedIn && !isPublicRoute) {
        return AppRoutes.login;
      }

      // Logged in and trying to access auth routes
      if (isLoggedIn && (currentPath == AppRoutes.login || currentPath == AppRoutes.register)) {
        return AppRoutes.home;
      }

      // Logged in and on landing
      if (isLoggedIn && currentPath == AppRoutes.landing) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // Public routes
      GoRoute(
        path: AppRoutes.landing,
        name: 'landing',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Protected routes with shell
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.wizard,
            name: 'wizard',
            builder: (context, state) => const WizardScreen(),
          ),
          GoRoute(
            path: AppRoutes.generationProgress,
            name: 'generationProgress',
            builder: (context, state) {
              final jobId = state.pathParameters['jobId']!;
              return GenerationProgressScreen(jobId: jobId);
            },
          ),
          GoRoute(
            path: AppRoutes.storyReader,
            name: 'storyReader',
            builder: (context, state) {
              final storyId = state.pathParameters['id']!;
              return ReaderScreen(storyId: storyId);
            },
          ),
          GoRoute(
            path: AppRoutes.library,
            name: 'library',
            builder: (context, state) => const LibraryScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Страница не найдена',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(AppRoutes.landing),
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// App Shell with bottom navigation
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
    );
  }
}
