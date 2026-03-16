import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/landing_assets.dart';
import '../../config/router.dart';
import '../../config/theme.dart';

// =============================================================================
// Landing Screen
// =============================================================================
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0A1D),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _HeroSection(isWide: isWide),
            _ShowcaseSection(isWide: isWide),
            _HowItWorksSection(isWide: isWide),
            _WhyTaleKidSection(isWide: isWide),
            _ReviewsSection(isWide: isWide),
            _CtaSection(isWide: isWide),
            _Footer(isWide: isWide),
          ],
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
      height: screenHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          if (LandingAssets.heroBg.isNotEmpty)
            CachedNetworkImage(
              imageUrl: LandingAssets.heroBg,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: const Color(0xFF0C0A1D)),
              errorWidget: (_, __, ___) =>
                  Container(color: const Color(0xFF0C0A1D)),
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

          // Scroll indicator at bottom
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
  final String page3Url;
  final String page7Url;
  final String text1;
  final String text3;
  final String text7;

  const _ShowcaseStoryData({
    required this.title,
    required this.description,
    required this.badge,
    required this.badgeColor,
    required this.coverUrl,
    required this.page3Url,
    required this.page7Url,
    required this.text1,
    required this.text3,
    required this.text7,
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

  static final _stories = [
    _ShowcaseStoryData(
      title: LandingAssets.tale1Title,
      description: 'Маша отправляется в зимний лес и встречает волшебных братьев-Месяцев, которые дарят ей весну посреди зимы',
      badge: 'Акварель',
      badgeColor: const Color(0xFF059669),
      coverUrl: LandingAssets.tale1Cover,
      page3Url: LandingAssets.tale1Page3,
      page7Url: LandingAssets.tale1Page7,
      text1: LandingAssets.tale1Text1,
      text3: LandingAssets.tale1Text3,
      text7: LandingAssets.tale1Text7,
    ),
    _ShowcaseStoryData(
      title: LandingAssets.tale2Title,
      description: 'Дима и кот Барсик летят в космос, знакомятся с инопланетянами и находят дорогу домой по звёздам',
      badge: '3D Анимация',
      badgeColor: const Color(0xFF6366F1),
      coverUrl: LandingAssets.tale2Cover,
      page3Url: LandingAssets.tale2Page3,
      page7Url: LandingAssets.tale2Page7,
      text1: LandingAssets.tale2Text1,
      text3: LandingAssets.tale2Text3,
      text7: LandingAssets.tale2Text7,
    ),
    _ShowcaseStoryData(
      title: LandingAssets.tale3Title,
      description: 'Русалочка Алиса спасает подводное королевство и устраивает праздник для обитателей океана',
      badge: 'Disney',
      badgeColor: const Color(0xFFDB2777),
      coverUrl: LandingAssets.tale3Cover,
      page3Url: LandingAssets.tale3Page3,
      page7Url: LandingAssets.tale3Page7,
      text1: LandingAssets.tale3Text1,
      text3: LandingAssets.tale3Text3,
      text7: LandingAssets.tale3Text7,
    ),
    _ShowcaseStoryData(
      title: LandingAssets.tale4Title,
      description: 'Мальчик получает суперсилу и узнаёт, что настоящая суперспособность — доброе сердце',
      badge: 'Комикс',
      badgeColor: const Color(0xFFD97706),
      coverUrl: LandingAssets.tale4Cover,
      page3Url: LandingAssets.tale4Page3,
      page7Url: LandingAssets.tale4Page7,
      text1: LandingAssets.tale4Text1,
      text3: LandingAssets.tale4Text3,
      text7: LandingAssets.tale4Text7,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    final screenHeight = MediaQuery.of(context).size.height;
    final cardWidth = widget.isWide
        ? screenWidth * 0.42
        : screenWidth * 0.88;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: screenHeight),
      color: const Color(0xFFFFFBF5),
      padding: EdgeInsets.symmetric(vertical: widget.isWide ? 80 : 56),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  'Четыре стиля — бесконечные истории',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.comfortaa(
                    fontSize: widget.isWide ? 40 : 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1C1917),
                  ),
                ),
                const SizedBox(height: 10),
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
          const SizedBox(height: 40),

          // Cards — horizontal scroll on desktop, vertical on mobile
          if (widget.isWide)
            Stack(
              children: [
                SizedBox(
                  height: 620,
                  child: ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                        horizontal: (screenWidth - cardWidth * 2 - 24) / 2),
                    itemCount: _stories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 24),
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
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: _stories
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _ShowcaseCard(
                            data: s,
                            isWide: widget.isWide,
                          ),
                        ))
                    .toList(),
              ),
            ),
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
        borderRadius: BorderRadius.circular(28),
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
                const BorderRadius.vertical(top: Radius.circular(28)),
            child: data.coverUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: data.coverUrl,
                    height: isWide ? 300 : 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _imagePlaceholder(isWide ? 300 : 220),
                    errorWidget: (_, __, ___) =>
                        _imagePlaceholder(isWide ? 300 : 220),
                  )
                : _imagePlaceholder(isWide ? 300 : 220),
          ),

          // Two page previews
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: data.page3Url.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: data.page3Url,
                            height: isWide ? 140 : 100,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                _imagePlaceholder(isWide ? 140 : 100),
                            errorWidget: (_, __, ___) =>
                                _imagePlaceholder(isWide ? 140 : 100),
                          )
                        : _imagePlaceholder(isWide ? 140 : 100),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: data.page7Url.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: data.page7Url,
                            height: isWide ? 140 : 100,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                _imagePlaceholder(isWide ? 140 : 100),
                            errorWidget: (_, __, ___) =>
                                _imagePlaceholder(isWide ? 140 : 100),
                          )
                        : _imagePlaceholder(isWide ? 140 : 100),
                  ),
                ),
              ],
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
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
                      '10 страниц \u00b7 10 мин',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 12,
                        color: const Color(0xFFA8A29E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  data.title,
                  style: GoogleFonts.comfortaa(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C1917),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 14,
                    color: const Color(0xFF78716C),
                  ),
                ),
                const SizedBox(height: 16),
                // "Посмотреть" button
                GestureDetector(
                  onTap: () => _openPreview(context, data),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.primaryColor, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        'Посмотреть',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
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
// Story Preview Dialog — fullscreen with PageView
// =============================================================================
class _StoryPreviewDialog extends StatefulWidget {
  final _ShowcaseStoryData data;
  const _StoryPreviewDialog({required this.data});

  @override
  State<_StoryPreviewDialog> createState() => _StoryPreviewDialogState();
}

class _StoryPreviewDialogState extends State<_StoryPreviewDialog> {
  int _current = 0;

  List<_PreviewPage> get _pages => [
        _PreviewPage(widget.data.coverUrl, widget.data.text1),
        _PreviewPage(widget.data.page3Url, widget.data.text3),
        _PreviewPage(widget.data.page7Url, widget.data.text7),
      ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final pages = _pages;
    final page = pages[_current];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isWide ? 40 : 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isWide ? 24 : 0),
        child: Container(
          width: isWide ? 700 : double.infinity,
          height: isWide ? 550 : double.infinity,
          color: const Color(0xFF0C0A1D),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              if (page.imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: page.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: const Color(0xFF0C0A1D)),
                  errorWidget: (_, __, ___) =>
                      Container(color: const Color(0xFF0C0A1D)),
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
                              '${_current + 1} / ${pages.length}',
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
              if (page.text.isNotEmpty)
                Positioned(
                  bottom: 70,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight:
                              MediaQuery.of(context).size.height * 0.20,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        color: Colors.black.withValues(alpha: 0.45),
                        child: SingleChildScrollView(
                          child: Text(
                            page.text,
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
              if (_current < pages.length - 1)
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

              // Bottom — CTA + dots
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
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
                      // Page dots
                      for (int i = 0; i < pages.length; i++)
                        Container(
                          width: i == _current ? 20 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: i == _current
                                ? AppTheme.primaryColor
                                : Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      const SizedBox(width: 24),
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

class _PreviewPage {
  final String imageUrl;
  final String text;
  const _PreviewPage(this.imageUrl, this.text);
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
// SECTION 3: HOW IT WORKS — 3 steps
// =============================================================================
class _HowItWorksSection extends StatelessWidget {
  final bool isWide;
  const _HowItWorksSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: screenHeight),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFFFF8F0)],
        ),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: 24, vertical: isWide ? 80 : 56),
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
              SizedBox(height: isWide ? 56 : 40),
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
                    const SizedBox(width: 24),
                    Expanded(child: _StepCard(
                      step: '2',
                      imageUrl: LandingAssets.howStep2,
                      title: 'Настройте мир',
                      description: 'Выберите стиль, жанр и мир — от акварели до комикса',
                      color: AppTheme.secondaryColor,
                    )),
                    const SizedBox(width: 24),
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
                    const SizedBox(height: 24),
                    _StepCard(
                      step: '2',
                      imageUrl: LandingAssets.howStep2,
                      title: 'Настройте мир',
                      description: 'Выберите стиль, жанр и мир — от акварели до комикса',
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(height: 24),
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
            CachedNetworkImage(
              imageUrl: imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 200,
                color: color.withValues(alpha: 0.08),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 200,
                color: color.withValues(alpha: 0.08),
                child: Icon(Icons.image, size: 40,
                    color: color.withValues(alpha: 0.3)),
              ),
            )
          else
            Container(
              height: 200,
              color: color.withValues(alpha: 0.08),
              child: Icon(Icons.image, size: 40,
                  color: color.withValues(alpha: 0.3)),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Step number circle
                Container(
                  width: 36,
                  height: 36,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.comfortaa(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C1917),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 14,
                    color: const Color(0xFF78716C),
                    height: 1.5,
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
    _FeatureData(Icons.palette, Color(0xFF8B5CF6), '4 стиля иллюстраций',
        'Акварель, 3D, Disney, комикс'),
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: screenHeight),
      color: const Color(0xFFFDF8F3),
      padding: EdgeInsets.symmetric(
          horizontal: 24, vertical: isWide ? 80 : 56),
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
              SizedBox(height: isWide ? 56 : 36),
              if (isWide)
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
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
                            padding: const EdgeInsets.only(bottom: 16),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(data.icon, size: 26, color: data.color),
          ),
          const SizedBox(width: 16),
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
          horizontal: 24, vertical: isWide ? 80 : 56),
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
              SizedBox(height: isWide ? 48 : 32),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _reviews
                      .map((r) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: _ReviewCard(data: r),
                            ),
                          ))
                      .toList(),
                )
              else
                Column(
                  children: _reviews
                      .map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
          const SizedBox(height: 14),
          Text(
            '\u00ab${data.text}\u00bb',
            style: GoogleFonts.nunitoSans(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF44403C),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: data.color,
                child: Text(
                  data.initial,
                  style: GoogleFonts.comfortaa(
                    color: Colors.white,
                    fontSize: 14,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C1917),
                    ),
                  ),
                  Text(
                    data.detail,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12,
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
// SECTION 6: CTA FINAL — 100vh, fullscreen background
// =============================================================================
class _CtaSection extends StatelessWidget {
  final bool isWide;
  const _CtaSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          if (LandingAssets.ctaBg.isNotEmpty)
            CachedNetworkImage(
              imageUrl: LandingAssets.ctaBg,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
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
                        fontSize: isWide ? 48 : 32,
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
                    const SizedBox(height: 14),
                    Text(
                      'Бесплатно. Регистрация за 30 секунд.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunitoSans(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 18,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
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
              const SizedBox(height: 16),
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
