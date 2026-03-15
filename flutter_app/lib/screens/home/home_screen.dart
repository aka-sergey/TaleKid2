import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../config/ui_assets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/story_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/shimmer_loading.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Доброй ночи';
    if (hour < 12) return 'Доброе утро';
    if (hour < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final storiesAsync = ref.watch(storiesProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Navbar ──────────────────────────────────────────
                  _NavBar(user: user, ref: ref),
                  const SizedBox(height: 32),

                  // ── Greeting ────────────────────────────────────────
                  Text(
                    '${_greeting()}, ${user?.displayName ?? 'друг'}!',
                    style: AppTheme.heading(size: 28),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Готовы к новому приключению?',
                    style: AppTheme.body(size: 15, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // ── Hero Card ───────────────────────────────────────
                  _HeroCard(onTap: () => context.go(AppRoutes.wizard)),
                  const SizedBox(height: 32),

                  // ── Recent Stories ──────────────────────────────────
                  storiesAsync.when(
                    data: (stories) {
                      final completed = stories
                          .where((s) => s.isCompleted)
                          .toList();
                      if (completed.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ваши сказки',
                                style: AppTheme.heading(size: 18),
                              ),
                              TextButton(
                                onPressed: () => context.go(AppRoutes.library),
                                child: Text(
                                  'Все ›',
                                  style: AppTheme.body(
                                    size: 14,
                                    weight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 200,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  completed.length > 8 ? 8 : completed.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (_, i) {
                                final story = completed[i];
                                return _StoryMiniCard(
                                  title: story.displayTitle,
                                  coverUrl: story.coverImageUrl,
                                  date: story.createdAt,
                                  onTap: () => context
                                      .go('/stories/${story.id}'),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],
                      );
                    },
                    loading: () => Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 4,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 14),
                          itemBuilder: (_, __) =>
                              const ShimmerBox(width: 150, height: 200, borderRadius: 20),
                        ),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // ── Library link ────────────────────────────────────
                  AppCard(
                    onTap: () => context.go(AppRoutes.library),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryLight.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.menu_book_rounded,
                              color: AppTheme.secondaryColor, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Библиотека',
                                  style: AppTheme.body(
                                      size: 15, weight: FontWeight.w700)),
                              storiesAsync.when(
                                data: (s) => Text(
                                  '${s.where((st) => st.isCompleted).length} сказок',
                                  style: AppTheme.body(
                                      size: 13,
                                      color: AppTheme.textSecondary),
                                ),
                                loading: () => const ShimmerBox(
                                    width: 60, height: 14, borderRadius: 6),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppTheme.textLight),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private Widgets ─────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  const _NavBar({required this.user, required this.ref});
  final dynamic user;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName ?? user?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Row(
      children: [
        // Logo
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.auto_stories, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Text('TaleKID',
            style: AppTheme.heading(size: 18, weight: FontWeight.w700)),
        const Spacer(),
        // User
        if (user != null) ...[
          Text(
            user.displayName ?? '',
            style: AppTheme.body(
                size: 14,
                weight: FontWeight.w600,
                color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.landing);
            },
            child: CircleAvatar(
              radius: 19,
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: AppTheme.body(
                        size: 14,
                        weight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative stars
            ..._decorativeStars(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Создать новую\nсказку',
                        style: AppTheme.heading(
                          size: 24,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Персонализированная история\nс иллюстрациями',
                        style: AppTheme.body(
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Начать ✨',
                          style: AppTheme.body(
                            size: 14,
                            weight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: UiAssets.hero_create_story,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.auto_stories,
                          color: Colors.white54, size: 40),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _decorativeStars() {
    const positions = [
      (8.0, 8.0),
      (60.0, -2.0),
      (180.0, 5.0),
      (280.0, 10.0),
      (40.0, 90.0),
      (310.0, 80.0),
    ];
    return positions
        .map((p) => Positioned(
              left: p.$1,
              top: p.$2,
              child: Icon(Icons.star_rounded,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.12)),
            ))
        .toList();
  }
}

class _StoryMiniCard extends StatefulWidget {
  const _StoryMiniCard({
    required this.title,
    this.coverUrl,
    required this.date,
    required this.onTap,
  });

  final String title;
  final String? coverUrl;
  final DateTime date;
  final VoidCallback onTap;

  @override
  State<_StoryMiniCard> createState() => _StoryMiniCardState();
}

class _StoryMiniCardState extends State<_StoryMiniCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 150,
          transform: Matrix4.translationValues(0, _hovering ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow:
                _hovering ? AppTheme.cardShadowHover : AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: widget.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: widget.coverUrl!,
                        height: 120,
                        width: 150,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 120,
                          color: AppTheme.fillColor,
                        ),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(size: 13, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d MMM', 'ru').format(widget.date),
                      style: AppTheme.body(
                          size: 11, color: AppTheme.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 120,
      width: 150,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE0E7FF), Color(0xFFF5F3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.auto_stories,
          color: AppTheme.primaryLight, size: 32),
    );
  }
}
