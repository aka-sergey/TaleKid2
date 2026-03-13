import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../config/theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryDark,
                  ],
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
                vertical: isWide ? 80 : 48,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      // App bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TaleKID',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => context.go(AppRoutes.login),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Войти'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => context.go(AppRoutes.register),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primaryColor,
                                ),
                                child: const Text('Регистрация'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: isWide ? 64 : 40),

                      // Hero text
                      Text(
                        'Персонализированные\nсказки для вашего ребёнка',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isWide ? 48 : 32,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Создавайте уникальные иллюстрированные истории '
                        'с вашим ребёнком в главной роли',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: isWide ? 20 : 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => context.go(AppRoutes.register),
                        icon: const Icon(Icons.auto_stories),
                        label: const Text('Создать сказку бесплатно'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          foregroundColor: AppTheme.textPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 18,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Features Section
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      Text(
                        'Как это работает',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 40),
                      Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        children: [
                          _FeatureCard(
                            icon: Icons.person_add,
                            title: 'Создайте персонажа',
                            description:
                                'Загрузите фото ребёнка, укажите имя и возраст',
                            isWide: isWide,
                          ),
                          _FeatureCard(
                            icon: Icons.tune,
                            title: 'Настройте сказку',
                            description:
                                'Выберите жанр, мир, сказку-основу и длительность',
                            isWide: isWide,
                          ),
                          _FeatureCard(
                            icon: Icons.auto_awesome,
                            title: 'Получите результат',
                            description:
                                'AI создаст уникальную иллюстрированную историю',
                            isWide: isWide,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Example Stories Section (placeholder)
            Container(
              width: double.infinity,
              color: AppTheme.backgroundColor,
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      Text(
                        'Примеры сказок',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 32),
                      // TODO: Replace with real example stories
                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: List.generate(
                          3,
                          (i) => _ExampleStoryCard(
                            title: [
                              'Маша и волшебный лес',
                              'Космическое приключение Димы',
                              'Подводное королевство Алисы',
                            ][i],
                            isWide: isWide,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              width: double.infinity,
              color: AppTheme.textPrimary,
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      const Text(
                        'TaleKID',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        children: [
                          TextButton(
                            onPressed: () {}, // TODO: navigate to terms
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                            ),
                            child: const Text('Пользовательское соглашение'),
                          ),
                          TextButton(
                            onPressed: () {}, // TODO: navigate to privacy
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                            ),
                            child: const Text('Политика конфиденциальности'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '\u00a9 2025 TaleKID. Все права защищены.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isWide;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isWide ? 260 : double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(icon, size: 32, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExampleStoryCard extends StatelessWidget {
  final String title;
  final bool isWide;

  const _ExampleStoryCard({
    required this.title,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isWide ? 260 : double.infinity,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Placeholder image
            Container(
              height: 180,
              color: AppTheme.primaryLight.withValues(alpha: 0.3),
              child: const Center(
                child: Icon(
                  Icons.image,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
