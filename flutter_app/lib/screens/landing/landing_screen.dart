import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../config/ui_assets.dart';
import '../../widgets/app_card.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
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
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFF4338CA),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: isWide ? 32 : 20,
            ),
            child: Column(
              children: [
                // Nav bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_stories,
                              color: AppTheme.accentColor, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'TaleKID',
                          style: GoogleFonts.comfortaa(
                            color: Colors.white,
                            fontSize: 22,
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          child: Text('Войти',
                              style: GoogleFonts.nunitoSans(
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.register),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Регистрация',
                              style: GoogleFonts.nunitoSans(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: isWide ? 60 : 40),

                // Hero content — text + image side by side on wide
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _HeroText(isWide: isWide),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        flex: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: CachedNetworkImage(
                            imageUrl: UiAssets.landing_hero,
                            fit: BoxFit.cover,
                            height: 320,
                            placeholder: (_, __) => Container(
                              height: 320,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              height: 320,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: const Icon(Icons.auto_stories,
                                  size: 80, color: Colors.white30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else ...[
                  _HeroText(isWide: isWide),
                  const SizedBox(height: 32),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CachedNetworkImage(
                      imageUrl: UiAssets.landing_hero,
                      fit: BoxFit.cover,
                      height: 200,
                      width: double.infinity,
                      placeholder: (_, __) => Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
                SizedBox(height: isWide ? 60 : 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  final bool isWide;
  const _HeroText({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          'Персонализированные\nсказки для вашего ребёнка',
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: GoogleFonts.comfortaa(
            color: Colors.white,
            fontSize: isWide ? 40 : 28,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'AI создаёт уникальные иллюстрированные истории, '
          'где ваш ребёнок — главный герой. '
          'С образовательным контентом на каждой странице.',
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: GoogleFonts.nunitoSans(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: isWide ? 18 : 15,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: () => context.go(AppRoutes.register),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentColor.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_stories,
                    color: AppTheme.textPrimary, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Создать сказку бесплатно',
                  style: GoogleFonts.comfortaa(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Бесплатно. Без ограничений.',
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: GoogleFonts.nunitoSans(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
      ],
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
      padding: EdgeInsets.symmetric(
          horizontal: 24, vertical: isWide ? 64 : 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Text(
                'Как это работает',
                style: AppTheme.heading(size: isWide ? 28 : 24),
              ),
              const SizedBox(height: 6),
              Text(
                '3 простых шага до волшебной сказки',
                style: AppTheme.body(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
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
      child: AppCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.8)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        step,
                        style: GoogleFonts.comfortaa(
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
              style: AppTheme.heading(size: 15),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTheme.body(
                size: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
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
      color: AppTheme.fillColor,
      padding: EdgeInsets.symmetric(
          horizontal: 24, vertical: isWide ? 64 : 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Text(
                'Почему TaleKID?',
                style: AppTheme.heading(size: isWide ? 28 : 24),
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 12,
                runSpacing: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.nunitoSans(
              fontSize: 13,
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
      color: Color(0xFF34D399),
      icon: Icons.forest,
    ),
    _ExampleData(
      title: 'Космическое приключение Димы',
      genre: 'Научная фантастика',
      world: 'Космос',
      description:
          'Дима становится юным космонавтом и исследует '
          'далёкие планеты, помогая инопланетным друзьям.',
      color: Color(0xFF8B5CF6),
      icon: Icons.rocket_launch,
    ),
    _ExampleData(
      title: 'Подводное королевство Алисы',
      genre: 'Фэнтези',
      world: 'Подводный мир',
      description:
          'Алиса открывает вход в подводное королевство '
          'и помогает морским жителям спасти коралловый риф.',
      color: Color(0xFF38BDF8),
      icon: Icons.water,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: 24, vertical: isWide ? 64 : 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Text(
                'Примеры сказок',
                style: AppTheme.heading(size: isWide ? 28 : 24),
              ),
              const SizedBox(height: 6),
              Text(
                'Вот что может создать TaleKID',
                style: AppTheme.body(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
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
      width: isWide ? 270 : double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor, width: 0.5),
          boxShadow: AppTheme.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    data.color.withValues(alpha: 0.2),
                    data.color.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    data.icon,
                    size: 36,
                    color: data.color,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: AppTheme.heading(size: 15),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Tag(label: data.genre, color: data.color),
                      const SizedBox(width: 6),
                      _Tag(label: data.world, color: data.color),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data.description,
                    style: AppTheme.body(
                      size: 13,
                      color: AppTheme.textSecondary,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunitoSans(
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
            Color(0xFF6366F1),
            Color(0xFFFB7185),
          ],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isWide ? 56 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Text(
                'Готовы создать сказку?',
                textAlign: TextAlign.center,
                style: GoogleFonts.comfortaa(
                  color: Colors.white,
                  fontSize: isWide ? 30 : 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Зарегистрируйтесь и создайте первую историю за 5 минут',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunitoSans(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => context.go(AppRoutes.register),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_forward,
                          color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Начать бесплатно',
                        style: GoogleFonts.comfortaa(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
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
      color: const Color(0xFF1C1917),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_stories,
                        color: AppTheme.accentColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'TaleKID',
                    style: GoogleFonts.comfortaa(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => context.go(AppRoutes.terms),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.white60),
                    child: Text('Соглашение',
                        style: GoogleFonts.nunitoSans(fontSize: 13)),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.privacy),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.white60),
                    child: Text('Конфиденциальность',
                        style: GoogleFonts.nunitoSans(fontSize: 13)),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.consent),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.white60),
                    child: Text('Согласие на обработку',
                        style: GoogleFonts.nunitoSans(fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '\u00a9 2025 TaleKID. Все права защищены.',
                style: GoogleFonts.nunitoSans(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
