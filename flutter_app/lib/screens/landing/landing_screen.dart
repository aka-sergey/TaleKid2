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
            // ---- Hero Section ----
            _HeroSection(isWide: isWide),

            // ---- How It Works ----
            _HowItWorksSection(isWide: isWide),

            // ---- Features ----
            _WhyTaleKidSection(isWide: isWide),

            // ---- Example Stories ----
            _ExampleStoriesSection(isWide: isWide),

            // ---- CTA Banner ----
            _CtaBanner(isWide: isWide),

            // ---- Footer ----
            _Footer(isWide: isWide),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Hero Section
// =============================================================================
class _HeroSection extends StatelessWidget {
  final bool isWide;
  const _HeroSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryDark,
            Color(0xFF2D1B69),
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
              // Nav bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_stories,
                          color: AppTheme.accentColor, size: 28),
                      const SizedBox(width: 8),
                      const Text(
                        'TaleKID',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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
              SizedBox(height: isWide ? 80 : 48),

              // Hero content
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
                'AI создаёт уникальные иллюстрированные истории, '
                'где ваш ребёнок — главный герой. '
                'С образовательным контентом на каждой странице.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: isWide ? 20 : 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
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
              const SizedBox(height: 16),
              Text(
                'Бесплатно. Без ограничений.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// How It Works
// =============================================================================
class _HowItWorksSection extends StatelessWidget {
  final bool isWide;
  const _HowItWorksSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLg, vertical: AppTheme.spacingXxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Text(
                'Как это работает',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '3 простых шага до волшебной сказки',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  _StepCard(
                    step: '1',
                    icon: Icons.person_add,
                    color: AppTheme.primaryColor,
                    title: 'Создайте персонажа',
                    description:
                        'Загрузите фото ребёнка, укажите имя и возраст. '
                        'AI проанализирует внешность для иллюстраций.',
                    isWide: isWide,
                  ),
                  _StepCard(
                    step: '2',
                    icon: Icons.tune,
                    color: AppTheme.secondaryColor,
                    title: 'Настройте сказку',
                    description:
                        'Выберите жанр, волшебный мир, сказку-основу. '
                        'Настройте длительность и образовательность.',
                    isWide: isWide,
                  ),
                  _StepCard(
                    step: '3',
                    icon: Icons.auto_awesome,
                    color: AppTheme.accentColor,
                    title: 'Наслаждайтесь!',
                    description:
                        'Через несколько минут получите уникальную '
                        'иллюстрированную сказку. Читайте, скачивайте PDF, делитесь.',
                    isWide: isWide,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool isWide;

  const _StepCard({
    required this.step,
    required this.icon,
    required this.color,
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
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(icon, size: 32, color: color),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          step,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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

// =============================================================================
// Why TaleKID — feature highlights
// =============================================================================
class _WhyTaleKidSection extends StatelessWidget {
  final bool isWide;
  const _WhyTaleKidSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.primaryColor.withValues(alpha: 0.04),
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLg, vertical: AppTheme.spacingXxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Text(
                'Почему TaleKID?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: const [
                  _FeatureChip(
                    icon: Icons.face,
                    label: 'Ребёнок в главной роли',
                  ),
                  _FeatureChip(
                    icon: Icons.palette,
                    label: 'AI-иллюстрации',
                  ),
                  _FeatureChip(
                    icon: Icons.school,
                    label: 'Образовательный контент',
                  ),
                  _FeatureChip(
                    icon: Icons.library_books,
                    label: '50+ сказок-основ',
                  ),
                  _FeatureChip(
                    icon: Icons.public,
                    label: '30 волшебных миров',
                  ),
                  _FeatureChip(
                    icon: Icons.theater_comedy,
                    label: '30 жанров',
                  ),
                  _FeatureChip(
                    icon: Icons.picture_as_pdf,
                    label: 'Экспорт в PDF',
                  ),
                  _FeatureChip(
                    icon: Icons.share,
                    label: 'Поделиться с друзьями',
                  ),
                  _FeatureChip(
                    icon: Icons.money_off,
                    label: 'Полностью бесплатно',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Example Stories
// =============================================================================
class _ExampleStoriesSection extends StatelessWidget {
  final bool isWide;
  const _ExampleStoriesSection({required this.isWide});

  static const _examples = [
    _ExampleData(
      title: 'Маша и волшебный лес',
      genre: 'Приключение',
      world: 'Заколдованный лес',
      description:
          'Маша отправляется в путешествие по волшебному лесу, '
          'где встречает говорящих зверей и разгадывает загадки.',
      color: Color(0xFF00B894),
      icon: Icons.forest,
    ),
    _ExampleData(
      title: 'Космическое приключение Димы',
      genre: 'Научная фантастика',
      world: 'Космос',
      description:
          'Дима становится юным космонавтом и исследует '
          'далёкие планеты, помогая инопланетным друзьям.',
      color: Color(0xFF6C5CE7),
      icon: Icons.rocket_launch,
    ),
    _ExampleData(
      title: 'Подводное королевство Алисы',
      genre: 'Фэнтези',
      world: 'Подводный мир',
      description:
          'Алиса открывает вход в подводное королевство '
          'и помогает морским жителям спасти коралловый риф.',
      color: Color(0xFF0984E3),
      icon: Icons.water,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLg, vertical: AppTheme.spacingXxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Text(
                'Примеры сказок',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Вот что может создать TaleKID',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: _examples
                    .map((e) => _ExampleStoryCard(data: e, isWide: isWide))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExampleData {
  final String title;
  final String genre;
  final String world;
  final String description;
  final Color color;
  final IconData icon;

  const _ExampleData({
    required this.title,
    required this.genre,
    required this.world,
    required this.description,
    required this.color,
    required this.icon,
  });
}

class _ExampleStoryCard extends StatelessWidget {
  final _ExampleData data;
  final bool isWide;

  const _ExampleStoryCard({required this.data, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isWide ? 260 : double.infinity,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    data.color.withValues(alpha: 0.3),
                    data.color.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  data.icon,
                  size: 64,
                  color: data.color.withValues(alpha: 0.7),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Tag(label: data.genre, color: data.color),
                      const SizedBox(width: 6),
                      _Tag(label: data.world, color: data.color),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =============================================================================
// CTA Banner
// =============================================================================
class _CtaBanner extends StatelessWidget {
  final bool isWide;
  const _CtaBanner({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
          ],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: isWide ? 60 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Text(
                'Готовы создать сказку?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isWide ? 32 : 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Зарегистрируйтесь и создайте первую историю за 5 минут',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.register),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Начать бесплатно'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Footer
// =============================================================================
class _Footer extends StatelessWidget {
  final bool isWide;
  const _Footer({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.textPrimary,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_stories,
                      color: AppTheme.accentColor, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'TaleKID',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => context.go(AppRoutes.terms),
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                    child: const Text('Пользовательское соглашение'),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.privacy),
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                    child: const Text('Политика конфиденциальности'),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.consent),
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                    child: const Text('Согласие на обработку'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
    );
  }
}
