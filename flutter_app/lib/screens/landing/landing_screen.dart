import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/landing_assets.dart';
import '../../config/router.dart';
import '../../config/theme.dart';

// =============================================================================
// Landing Screen
// =============================================================================
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scrollCtrl = ScrollController();
  bool _showStickyHeader = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final show = _scrollCtrl.offset > 180;
    if (show != _showStickyHeader) setState(() => _showStickyHeader = show);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    final sections = [
      _HeroSection(isWide: isWide),
      _ShowcaseSection(isWide: isWide),
      _StylesSection(isWide: isWide),
      _HowItWorksSection(isWide: isWide),
      _WhyTaleKidSection(isWide: isWide),
      _ReviewsSection(isWide: isWide),
      _CtaSection(isWide: isWide),
      _Footer(isWide: isWide),
    ];

    // ── Web: unchanged behaviour ─────────────────────────────────────────────
    if (isWide) {
      return Scaffold(
        backgroundColor: const Color(0xFF0C0A1D),
        body: SingleChildScrollView(child: Column(children: sections)),
      );
    }

    // ── Mobile: scroll tracked + sticky header overlay ───────────────────────
    return Scaffold(
      backgroundColor: const Color(0xFF0C0A1D),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollCtrl,
            child: Column(children: sections),
          ),
          AnimatedSlide(
            offset: _showStickyHeader ? Offset.zero : const Offset(0, -1),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _showStickyHeader ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const _MobileStickyHeader(),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Mobile Sticky Header — State B (appears after scroll threshold)
// =============================================================================
class _MobileStickyHeader extends StatelessWidget {
  const _MobileStickyHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0B1E).withValues(alpha: 0.97),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.auto_stories,
                    color: AppTheme.accentColor, size: 17),
              ),
              const SizedBox(width: 8),
              Text(
                'TaleKID',
                style: GoogleFonts.comfortaa(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Войти',
                    style: GoogleFonts.nunitoSans(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => context.go(AppRoutes.register),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Создать',
                    style: GoogleFonts.nunitoSans(
                      color: const Color(0xFF1C1917),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
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
// SECTION 1: HERO — 100vh, fullscreen image, gradient overlay
// =============================================================================
class _HeroSection extends StatelessWidget {
  final bool isWide;
  const _HeroSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: isWide ? screenHeight : screenHeight * 0.90,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          if (LandingAssets.heroBg.isNotEmpty)
            LandingImage(
              src: LandingAssets.heroBg,
              fit: BoxFit.cover,
              errorWidget: Container(color: const Color(0xFF0C0A1D)),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4338CA), Color(0xFF6366F1), Color(0xFF2A1F6F)],
                ),
              ),
            ),

          // Gradient overlays
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.6),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          // Navbar — top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Row(
                      children: [
                        // Logo
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
                        const Spacer(),
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
                  ),
                ),
              ),
            ),
          ),

          // Center content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ваш ребёнок — герой\nволшебной сказки',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.comfortaa(
                        color: Colors.white,
                        fontSize: isWide ? 56 : 36,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'AI создаёт уникальные иллюстрированные истории\n'
                      'с вашим ребёнком в главной роли',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunitoSans(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: isWide ? 20 : 16,
                        height: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.register),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentColor.withValues(alpha: 0.5),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_stories,
                                color: Color(0xFF1C1917), size: 22),
                            const SizedBox(width: 10),
                            Text(
                              'Создать сказку бесплатно',
                              style: GoogleFonts.comfortaa(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1C1917),
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
          ),

          // Scroll indicator at bottom — web only
          if (isWide)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Листай вниз',
                      style: GoogleFonts.nunitoSans(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(Icons.keyboard_arrow_down,
                        color: Colors.white.withValues(alpha: 0.5), size: 24),
                  ],
                ),
              ),
            ),

          // Mobile bottom bridge — rounded white tab merging into showcase bg
          if (!isWide)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFBF5),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION 2: SHOWCASE — 4 story cards
// =============================================================================

class _ShowcaseStoryData {
  final String title;
  final String description;
  final String badge;
  final Color badgeColor;
  final String coverUrl;
  final List<String> pageUrls;
  final List<String> pageTexts;

  const _ShowcaseStoryData({
    required this.title,
    required this.description,
    required this.badge,
    required this.badgeColor,
    required this.coverUrl,
    required this.pageUrls,
    required this.pageTexts,
  });
}

class _ShowcaseSection extends StatefulWidget {
  final bool isWide;
  const _ShowcaseSection({required this.isWide});

  @override
  State<_ShowcaseSection> createState() => _ShowcaseSectionState();
}

class _ShowcaseSectionState extends State<_ShowcaseSection> {
  late final ScrollController _scrollController;
  late final PageController _pageController;
  int _currentPage = 0;

  static final _stories = [
    _ShowcaseStoryData(
      title: LandingAssets.tale1Title,
      description: 'Маша отправляется в зимний лес и встречает волшебных братьев-Месяцев',
      badge: 'Акварель',
      badgeColor: const Color(0xFF059669),
      coverUrl: LandingAssets.tale1Cover,
      pageUrls: LandingAssets.tale1Pages,
      pageTexts: LandingAssets.tale1Texts,
    ),
    _ShowcaseStoryData(
      title: LandingAssets.tale2Title,
      description: 'Дима и кот Барсик летят в космос и находят дорогу домой по звёздам',
      badge: '3D Анимация',
      badgeColor: const Color(0xFF6366F1),
      coverUrl: LandingAssets.tale2Cover,
      pageUrls: LandingAssets.tale2Pages,
      pageTexts: LandingAssets.tale2Texts,
    ),
    _ShowcaseStoryData(
      title: LandingAssets.tale3Title,
      description: 'Русалочка Алиса спасает подводное королевство с помощью волшебных жемчужин',
      badge: 'Disney',
      badgeColor: const Color(0xFFDB2777),
      coverUrl: LandingAssets.tale3Cover,
      pageUrls: LandingAssets.tale3Pages,
      pageTexts: LandingAssets.tale3Texts,
    ),
    _ShowcaseStoryData(
      title: LandingAssets.tale4Title,
      description: 'Мальчик получает суперсилу и узнаёт, что настоящая суперспособность — доброе сердце',
      badge: 'Комикс',
      badgeColor: const Color(0xFFD97706),
      coverUrl: LandingAssets.tale4Cover,
      pageUrls: LandingAssets.tale4Pages,
      pageTexts: LandingAssets.tale4Texts,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    _scrollController.animateTo(
      (_scrollController.offset + delta).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = widget.isWide
        ? screenWidth * 0.42
        : screenWidth * 0.88;

    return Container(
      width: double.infinity,
      color: const Color(0xFFFFFBF5),
      padding: EdgeInsets.symmetric(vertical: widget.isWide ? 56 : 40),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  'Примеры сказок',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.comfortaa(
                    fontSize: widget.isWide ? 40 : 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1C1917),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Каждая сказка уникальна. Ваш ребёнок — главный герой.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    color: const Color(0xFF78716C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Cards — horizontal scroll on desktop, vertical on mobile
          if (widget.isWide)
            Stack(
              children: [
                SizedBox(
                  height: 540,
                  child: ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                        horizontal: (screenWidth - cardWidth * 2 - 24) / 2),
                    itemCount: _stories.length,
                    separatorBuilder: (ctx, i) => const SizedBox(width: 24),
                    itemBuilder: (_, i) => SizedBox(
                      width: cardWidth,
                      child: _ShowcaseCard(
                        data: _stories[i],
                        isWide: widget.isWide,
                      ),
                    ),
                  ),
                ),
                // Left arrow
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ScrollArrow(
                      icon: Icons.arrow_back_ios_new,
                      onTap: () => _scrollBy(-cardWidth - 24),
                    ),
                  ),
                ),
                // Right arrow
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ScrollArrow(
                      icon: Icons.arrow_forward_ios,
                      onTap: () => _scrollBy(cardWidth + 24),
                    ),
                  ),
                ),
              ],
            )
          // ── Mobile: horizontal PageView carousel ──────────────────────────
          else ...[
            SizedBox(
              height: 430,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _stories.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _ShowcaseCard(data: _stories[i], isWide: false),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Page dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_stories.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? AppTheme.primaryColor
                        : Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ScrollArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ScrollArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF1C1917)),
      ),
    );
  }
}

class _ShowcaseCard extends StatelessWidget {
  final _ShowcaseStoryData data;
  final bool isWide;
  const _ShowcaseCard({required this.data, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cover image
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            child: data.coverUrl.isNotEmpty
                ? LandingImage(
                    src: data.coverUrl,
                    height: isWide ? 260 : 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: _imagePlaceholder(isWide ? 260 : 200),
                  )
                : _imagePlaceholder(isWide ? 260 : 200),
          ),

          // Two page previews (pages 3 and 7)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: data.pageUrls.length > 2
                        ? LandingImage(
                            src: data.pageUrls[2],
                            height: isWide ? 110 : 80,
                            fit: BoxFit.cover,
                            errorWidget: _imagePlaceholder(isWide ? 110 : 80),
                          )
                        : _imagePlaceholder(isWide ? 110 : 80),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: data.pageUrls.length > 6
                        ? LandingImage(
                            src: data.pageUrls[6],
                            height: isWide ? 110 : 80,
                            fit: BoxFit.cover,
                            errorWidget: _imagePlaceholder(isWide ? 110 : 80),
                          )
                        : _imagePlaceholder(isWide ? 110 : 80),
                  ),
                ),
              ],
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: data.badgeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        data.badge,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${data.pageUrls.length} страниц',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 12,
                        color: const Color(0xFFA8A29E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  data.title,
                  style: GoogleFonts.comfortaa(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C1917),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 13,
                    color: const Color(0xFF78716C),
                  ),
                ),
                const SizedBox(height: 10),
                // "Листать сказку" button — outlined on web, light text+arrow on mobile
                GestureDetector(
                  onTap: () => _openPreview(context, data),
                  child: isWide
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.primaryColor, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              'Листать сказку',
                              style: GoogleFonts.nunitoSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Листать сказку',
                                style: GoogleFonts.nunitoSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Icon(Icons.arrow_forward_ios,
                                  size: 12, color: AppTheme.primaryColor),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPreview(BuildContext context, _ShowcaseStoryData data) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _StoryPreviewDialog(data: data),
    );
  }

  Widget _imagePlaceholder(double height) {
    return Container(
      height: height,
      color: const Color(0xFFF5F3FF),
      child: const Center(
        child: Icon(Icons.auto_stories, size: 40, color: Color(0xFFD4D4D8)),
      ),
    );
  }
}

// =============================================================================
// Story Preview Dialog — fullscreen with all 10 pages
// =============================================================================
class _StoryPreviewDialog extends StatefulWidget {
  final _ShowcaseStoryData data;
  const _StoryPreviewDialog({required this.data});

  @override
  State<_StoryPreviewDialog> createState() => _StoryPreviewDialogState();
}

class _StoryPreviewDialogState extends State<_StoryPreviewDialog> {
  int _current = 0;

  int get _totalPages => widget.data.pageUrls.length;

  String get _currentImageUrl =>
      _current < _totalPages ? widget.data.pageUrls[_current] : '';

  String get _currentText =>
      _current < widget.data.pageTexts.length
          ? widget.data.pageTexts[_current]
          : '';

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isWide ? 24 : 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isWide ? 20 : 0),
        child: Container(
          width: isWide ? 900 : double.infinity,
          height: isWide ? (screenHeight * 0.85).clamp(500.0, 750.0) : double.infinity,
          color: const Color(0xFF0C0A1D),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              if (_currentImageUrl.isNotEmpty)
                LandingImage(
                  src: _currentImageUrl,
                  fit: BoxFit.cover,
                  errorWidget: Container(color: const Color(0xFF0C0A1D)),
                ),

              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text(
                              widget.data.title,
                              style: GoogleFonts.comfortaa(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: widget.data.badgeColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.data.badge,
                              style: GoogleFonts.nunitoSans(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_current + 1} / $_totalPages',
                              style: GoogleFonts.nunitoSans(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Text overlay at bottom
              if (_currentText.isNotEmpty)
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWide ? 700 : double.infinity,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.20,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  _currentText,
                                  style: GoogleFonts.nunitoSans(
                                    color: Colors.white,
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Nav arrows
              if (_current > 0)
                Positioned(
                  left: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _DialogArrow(
                      icon: Icons.arrow_back_ios_new,
                      onTap: () => setState(() => _current--),
                    ),
                  ),
                ),
              if (_current < _totalPages - 1)
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _DialogArrow(
                      icon: Icons.arrow_forward_ios,
                      onTap: () => setState(() => _current++),
                    ),
                  ),
                ),

              // Bottom — page indicator + CTA
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Compact page dots (show current region)
                      _CompactPageDots(
                        total: _totalPages,
                        current: _current,
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go(AppRoutes.register);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Создать свою сказку',
                            style: GoogleFonts.comfortaa(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1C1917),
                            ),
                          ),
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

/// Compact page dots that work well with 10 pages
class _CompactPageDots extends StatelessWidget {
  final int total;
  final int current;
  const _CompactPageDots({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return Container(
          width: isActive ? 16 : 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isActive
                ? AppTheme.primaryColor
                : Colors.white.withValues(alpha: 0.35),
          ),
        );
      }),
    );
  }
}

class _DialogArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _DialogArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

// =============================================================================
// SECTION 2.5: ILLUSTRATION STYLES — 8 styles
// =============================================================================
class _StylesSection extends StatelessWidget {
  final bool isWide;
  const _StylesSection({required this.isWide});

  static const _styles = [
    _StyleData('Акварель', Color(0xFF059669),
        'Мягкие цвета и нежные переходы'),
    _StyleData('3D Анимация (Pixar)', Color(0xFF6366F1),
        'Яркий мир как в мультфильмах Pixar'),
    _StyleData('Disney', Color(0xFFDB2777),
        'Волшебство в стиле Disney'),
    _StyleData('Комикс', Color(0xFFD97706),
        'Динамичные сцены с яркими контурами'),
    _StyleData('Аниме', Color(0xFF8B5CF6),
        'Японский стиль с большими глазами'),
    _StyleData('Пастель', Color(0xFF14B8A6),
        'Нежные пастельные тона для малышей'),
    _StyleData('Книжная классика', Color(0xFF0EA5E9),
        'Тёплый стиль классических иллюстраций'),
    _StyleData('Поп-арт', Color(0xFFF43F5E),
        'Смелые цвета и современный дизайн'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFBF5), Colors.white],
        ),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: 24, vertical: isWide ? 48 : 44),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Text(
                'Множество стилей иллюстраций',
                textAlign: TextAlign.center,
                style: GoogleFonts.comfortaa(
                  fontSize: isWide ? 36 : 26,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1C1917),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Выберите стиль, который понравится вашему ребёнку',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunitoSans(
                  fontSize: 16,
                  color: const Color(0xFF78716C),
                ),
              ),
              const SizedBox(height: 28),
              // Grid of style cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = isWide ? 4 : 2;
                  final spacing = isWide ? 16.0 : 12.0;
                  final itemWidth =
                      (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                          crossAxisCount;
                  final itemHeight = itemWidth * 0.85;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: List.generate(_styles.length, (i) {
                      final style = _styles[i];
                      final hasImage = LandingAssets.styleCovers.length > i &&
                          LandingAssets.styleCovers[i].isNotEmpty;

                      return SizedBox(
                        width: itemWidth,
                        height: itemHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Background — image or gradient
                              if (hasImage)
                                LandingImage(
                                  src: LandingAssets.styleCovers[i],
                                  fit: BoxFit.cover,
                                  errorWidget: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          style.color.withValues(alpha: 0.15),
                                          style.color.withValues(alpha: 0.05),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        style.color.withValues(alpha: 0.15),
                                        style.color.withValues(alpha: 0.05),
                                      ],
                                    ),
                                  ),
                                ),

                              // Dark overlay for text readability
                              // Mobile: stronger scrim for stable contrast
                              if (hasImage)
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(
                                            alpha: isWide ? 0.70 : 0.82),
                                      ],
                                      stops: isWide
                                          ? const [0.30, 1.0]
                                          : const [0.15, 1.0],
                                    ),
                                  ),
                                ),

                              // Label
                              Positioned(
                                bottom: 12,
                                left: 12,
                                right: 12,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      style.name,
                                      style: GoogleFonts.comfortaa(
                                        fontSize: isWide ? 14 : 13,
                                        fontWeight: FontWeight.w700,
                                        color: hasImage
                                            ? Colors.white
                                            : const Color(0xFF1C1917),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      style.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.nunitoSans(
                                        fontSize: 11,
                                        color: hasImage
                                            ? Colors.white.withValues(alpha: 0.8)
                                            : const Color(0xFF78716C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyleData {
  final String name;
  final Color color;
  final String description;
  const _StyleData(this.name, this.color, this.description);
}

// =============================================================================
// SECTION 3: HOW IT WORKS — 3 steps
// =============================================================================
class _HowItWorksSection extends StatelessWidget {
  final bool isWide;
  const _HowItWorksSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFFFF8F0)],
        ),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: 24, vertical: isWide ? 56 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Text(
                'Три шага до волшебства',
                textAlign: TextAlign.center,
                style: GoogleFonts.comfortaa(
                  fontSize: isWide ? 36 : 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1C1917),
                ),
              ),
              SizedBox(height: isWide ? 40 : 28),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _StepCard(
                      step: '1',
                      imageUrl: LandingAssets.howStep1,
                      title: 'Создайте персонажа',
                      description: 'Загрузите фото и имя. AI создаст героя, похожего на вашего малыша',
                      color: AppTheme.primaryColor,
                    )),
                    const SizedBox(width: 20),
                    Expanded(child: _StepCard(
                      step: '2',
                      imageUrl: LandingAssets.howStep2,
                      title: 'Настройте мир',
                      description: 'Выберите стиль, жанр и мир — от акварели до комикса',
                      color: AppTheme.secondaryColor,
                    )),
                    const SizedBox(width: 20),
                    Expanded(child: _StepCard(
                      step: '3',
                      imageUrl: LandingAssets.howStep3,
                      title: 'Наслаждайтесь!',
                      description: 'Через 5 минут — уникальная сказка. Читайте, скачайте PDF, подарите',
                      color: AppTheme.accentColor,
                    )),
                  ],
                )
              else
                Column(
                  children: [
                    _StepCard(
                      step: '1',
                      imageUrl: LandingAssets.howStep1,
                      title: 'Создайте персонажа',
                      description: 'Загрузите фото и имя. AI создаст героя, похожего на вашего малыша',
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 20),
                    _StepCard(
                      step: '2',
                      imageUrl: LandingAssets.howStep2,
                      title: 'Настройте мир',
                      description: 'Выберите стиль, жанр и мир — от акварели до комикса',
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(height: 20),
                    _StepCard(
                      step: '3',
                      imageUrl: LandingAssets.howStep3,
                      title: 'Наслаждайтесь!',
                      description: 'Через 5 минут — уникальная сказка. Читайте, скачайте PDF, подарите',
                      color: AppTheme.accentColor,
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
  final String imageUrl;
  final String title;
  final String description;
  final Color color;

  const _StepCard({
    required this.step,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Image
          if (imageUrl.isNotEmpty)
            LandingImage(
              src: imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorWidget: Container(
                height: 180,
                color: color.withValues(alpha: 0.08),
                child: Icon(Icons.image, size: 40,
                    color: color.withValues(alpha: 0.3)),
              ),
            )
          else
            Container(
              height: 180,
              color: color.withValues(alpha: 0.08),
              child: Icon(Icons.image, size: 40,
                  color: color.withValues(alpha: 0.3)),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Step number circle
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      step,
                      style: GoogleFonts.comfortaa(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.comfortaa(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C1917),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 13,
                    color: const Color(0xFF78716C),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION 4: WHY TALEKID — 6 features
// =============================================================================
class _WhyTaleKidSection extends StatelessWidget {
  final bool isWide;
  const _WhyTaleKidSection({required this.isWide});

  static const _features = [
    _FeatureData(Icons.face, Color(0xFF6366F1), 'Ребёнок — главный герой',
        'AI вплетает малыша в иллюстрации'),
    _FeatureData(Icons.palette, Color(0xFF8B5CF6), 'Множество стилей',
        'Акварель, 3D, Disney, аниме и другие'),
    _FeatureData(Icons.school, Color(0xFFF59E0B), 'Обучает играючи',
        'Факты и вопросы на каждой странице'),
    _FeatureData(Icons.bolt, Color(0xFF34D399), 'Готово за 5 минут',
        'AI делает всё, вы только читаете'),
    _FeatureData(Icons.menu_book, Color(0xFFFB7185), 'От 5 до 30 страниц',
        'Настройте длину под ситуацию'),
    _FeatureData(Icons.card_giftcard, Color(0xFF38BDF8), 'Идеальный подарок',
        'PDF, печать, подарок бабушке'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFDF8F3),
      padding: EdgeInsets.symmetric(
          horizontal: 24, vertical: isWide ? 56 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Text(
                'Больше чем просто сказка',
                textAlign: TextAlign.center,
                style: GoogleFonts.comfortaa(
                  fontSize: isWide ? 36 : 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1C1917),
                ),
              ),
              SizedBox(height: isWide ? 36 : 24),
              if (isWide)
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: _features
                      .map((f) => SizedBox(
                            width: 300,
                            child: _FeatureCard(data: f),
                          ))
                      .toList(),
                )
              else
                Column(
                  children: _features
                      .map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _FeatureCard(data: f),
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _FeatureData(this.icon, this.color, this.title, this.subtitle);
}

class _FeatureCard extends StatelessWidget {
  final _FeatureData data;
  const _FeatureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, size: 24, color: data.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: GoogleFonts.comfortaa(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C1917),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 13,
                    color: const Color(0xFF78716C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION 5: REVIEWS
// =============================================================================
class _ReviewsSection extends StatelessWidget {
  final bool isWide;
  const _ReviewsSection({required this.isWide});

  static const _reviews = [
    _ReviewData(
      text: 'Дочка каждый вечер просит сказку про себя. Увидела себя на картинке — визжала от восторга.',
      name: 'Елена',
      detail: 'мама Маши, 4 года',
      initial: 'Е',
      color: Color(0xFFDB2777),
    ),
    _ReviewData(
      text: 'Сын обожает космос. Создали сказку с ракетой и котом — перечитывает каждый день.',
      name: 'Алексей',
      detail: 'папа Димы, 5 лет',
      initial: 'А',
      color: Color(0xFF6366F1),
    ),
    _ReviewData(
      text: 'Подарила сестре. У племянницы 15 сказок, знает наизусть, рассказывает в садике!',
      name: 'Ольга',
      detail: 'тётя Алисы, 3 года',
      initial: 'О',
      color: Color(0xFF059669),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF5F0FF)],
        ),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: 24, vertical: isWide ? 56 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Text(
                'Родители в восторге',
                textAlign: TextAlign.center,
                style: GoogleFonts.comfortaa(
                  fontSize: isWide ? 36 : 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1C1917),
                ),
              ),
              SizedBox(height: isWide ? 36 : 24),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _reviews
                      .map((r) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: _ReviewCard(data: r),
                            ),
                          ))
                      .toList(),
                )
              else
                Column(
                  children: _reviews
                      .map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ReviewCard(data: r),
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewData {
  final String text;
  final String name;
  final String detail;
  final String initial;
  final Color color;
  const _ReviewData({
    required this.text,
    required this.name,
    required this.detail,
    required this.initial,
    required this.color,
  });
}

class _ReviewCard extends StatelessWidget {
  final _ReviewData data;
  const _ReviewCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stars
          Row(
            children: List.generate(
              5,
              (_) => const Icon(Icons.star, color: Color(0xFFF59E0B), size: 18),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '\u00ab${data.text}\u00bb',
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF44403C),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: data.color,
                child: Text(
                  data.initial,
                  style: GoogleFonts.comfortaa(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C1917),
                    ),
                  ),
                  Text(
                    data.detail,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 11,
                      color: const Color(0xFFA8A29E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION 6: CTA FINAL
// =============================================================================
class _CtaSection extends StatelessWidget {
  final bool isWide;
  const _CtaSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          if (LandingAssets.ctaBg.isNotEmpty)
            LandingImage(
              src: LandingAssets.ctaBg,
              fit: BoxFit.cover,
              errorWidget: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                  ),
                ),
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                ),
              ),
            ),

          // Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),

          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Создайте первую\nсказку прямо сейчас',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.comfortaa(
                        color: Colors.white,
                        fontSize: isWide ? 44 : 30,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Бесплатно. Регистрация за 30 секунд.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunitoSans(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 17,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.register),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.2),
                              blurRadius: 24,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_forward,
                                color: AppTheme.primaryColor, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              'Начать бесплатно',
                              style: GoogleFonts.comfortaa(
                                fontSize: 16,
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
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION 7: FOOTER
// =============================================================================
class _Footer extends StatelessWidget {
  final bool isWide;
  const _Footer({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isWide
            ? null
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0C0A1D), Color(0xFF1C1917)],
                stops: [0.0, 0.35],
              ),
        color: isWide ? const Color(0xFF1C1917) : null,
      ),
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
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => context.go(AppRoutes.terms),
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.white60),
                    child: Text('Соглашение',
                        style: GoogleFonts.nunitoSans(fontSize: 13)),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.privacy),
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.white60),
                    child: Text('Конфиденциальность',
                        style: GoogleFonts.nunitoSans(fontSize: 13)),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.consent),
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.white60),
                    child: Text('Согласие на обработку',
                        style: GoogleFonts.nunitoSans(fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '\u00a9 2026 TaleKID. Все права защищены.',
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
