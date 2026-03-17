import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

class _HeroCard extends StatefulWidget {
  const _HeroCard({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard>
    with SingleTickerProviderStateMixin {
  bool _btnHovering = false;
  late final AnimationController _shineCtrl;

  @override
  void initState() {
    super.initState();
    _shineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _shineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Background: book image full-bleed ──────────────────
              CachedNetworkImage(
                imageUrl: UiAssets.hero_create_story,
                fit: BoxFit.cover,
                placeholder: (_, __) => const _HeroFallbackBg(),
                errorWidget: (_, __, ___) => const _HeroFallbackBg(),
              ),

              // ── Gradient overlay: dark at top & bottom, transparent centre ──
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xCC08061A),
                      Color(0x55080618),
                      Color(0x33080618),
                      Color(0xBB08061A),
                      Color(0xEE06041A),
                    ],
                    stops: [0.0, 0.18, 0.45, 0.72, 1.0],
                  ),
                ),
              ),

              // ── Decorative sparkles ─────────────────────────────────
              ..._sparkles(),

              // ── Main content ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top badge — web only
                    if (kIsWeb)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          '✨  Магия искусственного интеллекта',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),

                    // Centre: title + subtitle
                    Column(
                      children: [
                        // Title: static on web, animated shine on mobile
                        if (kIsWeb)
                          const Text(
                            'Создать\nновую сказку',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.05,
                              letterSpacing: -0.5,
                              shadows: [
                                Shadow(
                                    color: Color(0xCC000000), blurRadius: 24),
                              ],
                            ),
                          )
                        else
                          AnimatedBuilder(
                            animation: _shineCtrl,
                            builder: (_, __) {
                              final t = _shineCtrl.value;
                              // breathing: glow pulses 0.7..1.0
                              final breath =
                                  0.7 + 0.3 * math.sin(t * math.pi);
                              // sweep position 0..1 for the ray
                              final pos = t;
                              return ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (bounds) =>
                                    LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: const [
                                    Color(0xFFFFCC00),
                                    Color(0xFFFFCC00),
                                    Color(0xFFFFFFAA),
                                    Color(0xFFFFCC00),
                                    Color(0xFFFFCC00),
                                  ],
                                  stops: [
                                    0.0,
                                    (pos - 0.12).clamp(0.0, 1.0),
                                    pos.clamp(0.0, 1.0),
                                    (pos + 0.12).clamp(0.0, 1.0),
                                    1.0,
                                  ],
                                ).createShader(bounds),
                                child: Opacity(
                                  opacity: breath,
                                  child: const Text(
                                    'Создать\nновую сказку',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1.05,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 16),
                        Text(
                          'Персонализированная история\nс красивыми иллюстрациями\nспециально для вашего ребёнка',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: kIsWeb ? 51 : 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.35,
                            shadows: const [
                              Shadow(
                                  color: Color(0xBB000000), blurRadius: 16),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Bottom: "Начать" button
                    MouseRegion(
                      onEnter: (_) =>
                          setState(() => _btnHovering = true),
                      onExit: (_) =>
                          setState(() => _btnHovering = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        transform: Matrix4.identity()
                          ..scale(_btnHovering ? 1.06 : 1.0),
                        transformAlignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 18),
                        decoration: BoxDecoration(
                          color: _btnHovering
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.93),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: _btnHovering
                                  ? const Color(0xFFFFDD00)
                                      .withValues(alpha: 0.65)
                                  : Colors.black.withValues(alpha: 0.25),
                              blurRadius: _btnHovering ? 36 : 12,
                              spreadRadius: _btnHovering ? 2 : 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Начать ✨',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4338CA),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
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

  List<Widget> _sparkles() {
    // (left, top, size, opacity)
    const pts = [
      (22.0, 22.0, 18.0, 0.45),
      (72.0, 10.0, 11.0, 0.28),
      (165.0, 18.0, 9.0, 0.22),
      (270.0, 14.0, 15.0, 0.38),
      (340.0, 28.0, 10.0, 0.25),
      (12.0, 240.0, 9.0, 0.20),
      (350.0, 220.0, 13.0, 0.28),
      (40.0, 380.0, 10.0, 0.22),
      (310.0, 370.0, 8.0, 0.20),
      (190.0, 38.0, 7.0, 0.18),
    ];
    return pts
        .map((p) => Positioned(
              left: p.$1,
              top: p.$2,
              child: Icon(
                Icons.star_rounded,
                size: p.$3,
                color: Colors.white.withValues(alpha: p.$4),
              ),
            ))
        .toList();
  }
}

/// Fallback gradient when image hasn't loaded yet.
class _HeroFallbackBg extends StatelessWidget {
  const _HeroFallbackBg();
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4338CA), Color(0xFF6366F1), Color(0xFF2A1F6F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.auto_stories, color: Colors.white38, size: 80),
        ),
      );
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
            color: AppTheme.glassLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.glassBorder, width: 0.5),
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
                child: widget.coverUrl != null && widget.coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.coverUrl!,
                        height: 120,
                        width: 150,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholder(),
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
          colors: [Color(0xFF1E1A40), Color(0xFF2A2050)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.auto_stories,
          color: AppTheme.primaryLight, size: 32),
    );
  }
}
