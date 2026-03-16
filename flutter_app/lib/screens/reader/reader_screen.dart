import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../models/story.dart';
import '../../providers/story_provider.dart';
import '../../services/pdf_service.dart';
import '../../services/share_service.dart';
import '../../widgets/educational_popup.dart';
import '../../widgets/title_dialog.dart';

/// Full-screen story reader.
///
/// - **Android**: horizontal PageView with swipe, landscape-friendly layout
/// - **Web**: vertical layout with navigation arrows, image + text below
class ReaderScreen extends ConsumerStatefulWidget {
  final String storyId;

  const ReaderScreen({super.key, required this.storyId});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _titleDialogShown = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restore orientation on dispose (Android)
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _showTitleDialog(StoryDetail story) async {
    if (_titleDialogShown) return;
    _titleDialogShown = true;

    // Only show if title is not yet set (only suggested)
    if (story.title != null && story.title!.isNotEmpty) return;

    final chosenTitle = await TitleDialog.show(
      context,
      suggestedTitle: story.titleSuggested,
      storyId: story.id,
    );

    if (chosenTitle != null && mounted) {
      await ref.read(storiesProvider.notifier).updateTitle(
            story.id,
            chosenTitle,
          );
    }
  }

  Future<void> _exportPdf(StoryDetail story) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Генерируем PDF...'),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      final pdfService = PdfService();
      final bytes = await pdfService.generateStoryPdf(story);
      await Printing.layoutPdf(onLayout: (_) => bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка PDF: $e')),
        );
      }
    }
  }

  Future<void> _shareStory(StoryDetail story) async {
    final shareService = ShareService();
    final copied = await shareService.shareStoryLink(
      storyId: story.id,
      storyTitle: story.displayTitle,
    );
    if (copied && kIsWeb && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ссылка скопирована!'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final storyAsync = ref.watch(storyDetailProvider(widget.storyId));

    return storyAsync.when(
      data: (story) {
        // Show title dialog once on first load
        if (!_titleDialogShown) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showTitleDialog(story);
          });
        }

        final pages = List<StoryPage>.from(story.pages)
          ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

        if (pages.isEmpty) {
          return _buildEmptyState(context);
        }

        return kIsWeb
            ? _buildWebReader(context, story, pages)
            : _buildMobileReader(context, story, pages);
      },
      loading: () => Scaffold(
        backgroundColor: const Color(0xFF1C1917),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryLight),
              const SizedBox(height: 16),
              Text(
                'Загружаем сказку...',
                style: GoogleFonts.comfortaa(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                  ),
                  child: const Icon(Icons.error_outline,
                      size: 40, color: AppTheme.errorColor),
                ),
                const SizedBox(height: 20),
                Text('Не удалось загрузить сказку',
                    style: AppTheme.heading(size: 20)),
                const SizedBox(height: 8),
                Text('$e',
                    textAlign: TextAlign.center,
                    style: AppTheme.body(color: AppTheme.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.invalidate(storyDetailProvider(widget.storyId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mobile Reader — horizontal PageView, immersive
  // ---------------------------------------------------------------------------
  Widget _buildMobileReader(
      BuildContext context, StoryDetail story, List<StoryPage> pages) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Page View
            PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                final page = pages[index];
                return _MobilePageView(page: page, story: story);
              },
            ),

            // Top overlay — back button, title, PDF, share
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopOverlay(
                story: story,
                currentPage: _currentPage,
                totalPages: pages.length,
                onBack: () => context.go(AppRoutes.library),
                onPdf: () => _exportPdf(story),
                onShare: () => _shareStory(story),
              ),
            ),

            // Bottom overlay — page dots & lightbulb
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomOverlay(
                pages: pages,
                currentPage: _currentPage,
                onPageTap: _goToPage,
                onLightbulb: pages[_currentPage].educationalContent != null
                    ? () => EducationalPopup.show(
                        context, pages[_currentPage].educationalContent!)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Web Reader — vertical layout with navigation
  // ---------------------------------------------------------------------------
  Widget _buildWebReader(
      BuildContext context, StoryDetail story, List<StoryPage> pages) {
    final page = pages[_currentPage];
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Custom top bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor, width: 0.5),
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.library),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.fillColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back,
                            size: 18, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        story.displayTitle,
                        style: AppTheme.heading(size: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Page counter pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentPage + 1} / ${pages.length}',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Lightbulb
                    if (page.educationalContent != null)
                      _ActionBtn(
                        icon: Icons.lightbulb,
                        color: AppTheme.accentColor,
                        tooltip: 'Узнать интересное!',
                        onTap: () => EducationalPopup.show(
                            context, page.educationalContent!),
                      ),
                    // PDF
                    _ActionBtn(
                      icon: Icons.picture_as_pdf,
                      tooltip: 'Скачать PDF',
                      onTap: () => _exportPdf(story),
                    ),
                    // Share
                    _ActionBtn(
                      icon: Icons.share,
                      tooltip: 'Поделиться',
                      onTap: () => _shareStory(story),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // ── Image + Text: side-by-side on wide, stacked on narrow ──
                      if (isWide)
                        // Wide: image left, text right
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image — 55%
                              Expanded(
                                flex: 55,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: AspectRatio(
                                    aspectRatio: 4 / 3,
                                    child: _pageImage(page),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Text — 45%
                              Expanded(
                                flex: 45,
                                child: page.textContent != null
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 28,
                                          vertical: 24,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: AppTheme.cardShadow,
                                        ),
                                        child: Text(
                                          page.textContent!,
                                          style: GoogleFonts.nunitoSans(
                                            fontSize: 17,
                                            height: 1.7,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        // Narrow: stacked vertically
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: _pageImage(page),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (page.textContent != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 24,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Text(
                              page.textContent!,
                              style: GoogleFonts.nunitoSans(
                                fontSize: 18,
                                height: 1.7,
                                color: AppTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                      const SizedBox(height: 32),

                      // Navigation arrows + page dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _NavArrow(
                            icon: Icons.arrow_back_ios_new,
                            enabled: _currentPage > 0,
                            onTap: () => setState(() => _currentPage--),
                          ),
                          const SizedBox(width: 20),
                          _PageDots(
                            total: pages.length,
                            current: _currentPage,
                          ),
                          const SizedBox(width: 20),
                          _NavArrow(
                            icon: Icons.arrow_forward_ios,
                            enabled: _currentPage < pages.length - 1,
                            onTap: () => setState(() => _currentPage++),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageImage(StoryPage page) {
    if (page.imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: page.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: AppTheme.primaryLight.withValues(alpha: 0.1),
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: AppTheme.primaryLight.withValues(alpha: 0.1),
          child: const Icon(Icons.broken_image,
              size: 64, color: AppTheme.textLight),
        ),
      );
    }
    return Container(
      color: AppTheme.primaryLight.withValues(alpha: 0.1),
      child: const Icon(Icons.image, size: 64, color: AppTheme.textLight),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryLight.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.menu_book,
                  size: 48, color: AppTheme.primaryLight),
            ),
            const SizedBox(height: 20),
            Text('Страницы ещё не готовы',
                style: AppTheme.heading(size: 20)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Action button for the web top bar
// =============================================================================
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: AppTheme.fillColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color ?? AppTheme.textSecondary),
        ),
      ),
    );
  }
}

// =============================================================================
// Navigation arrow button
// =============================================================================
class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: enabled ? AppTheme.primaryGradient : null,
          color: enabled ? null : AppTheme.fillColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.white : AppTheme.textLight,
        ),
      ),
    );
  }
}

// =============================================================================
// Mobile page view — fullscreen image + frosted glass text overlay
// =============================================================================
class _MobilePageView extends StatelessWidget {
  final StoryPage page;
  final StoryDetail story;

  const _MobilePageView({required this.page, required this.story});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        if (page.imageUrl != null)
          CachedNetworkImage(
            imageUrl: page.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white54),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: Colors.grey[900],
              child: const Icon(Icons.broken_image,
                  size: 64, color: Colors.white24),
            ),
          )
        else
          Container(
            color: Colors.grey[900],
            child: const Icon(Icons.image, size: 64, color: Colors.white24),
          ),

        // Frosted glass text overlay at bottom
        if (page.textContent != null)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      page.textContent!,
                      style: GoogleFonts.nunitoSans(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// Top overlay — back button, title, page count
// =============================================================================
class _TopOverlay extends StatelessWidget {
  final StoryDetail story;
  final int currentPage;
  final int totalPages;
  final VoidCallback onBack;
  final VoidCallback? onPdf;
  final VoidCallback? onShare;

  const _TopOverlay({
    required this.story,
    required this.currentPage,
    required this.totalPages,
    required this.onBack,
    this.onPdf,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onBack,
              ),
              Expanded(
                child: Text(
                  story.displayTitle,
                  style: GoogleFonts.comfortaa(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onPdf != null)
                IconButton(
                  icon:
                      const Icon(Icons.picture_as_pdf, color: Colors.white70),
                  onPressed: onPdf,
                  tooltip: 'PDF',
                ),
              if (onShare != null)
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white70),
                  onPressed: onShare,
                  tooltip: 'Поделиться',
                ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${currentPage + 1}/$totalPages',
                  style: GoogleFonts.nunitoSans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Bottom overlay — page dots + lightbulb
// =============================================================================
class _BottomOverlay extends StatelessWidget {
  final List<StoryPage> pages;
  final int currentPage;
  final ValueChanged<int> onPageTap;
  final VoidCallback? onLightbulb;

  const _BottomOverlay({
    required this.pages,
    required this.currentPage,
    required this.onPageTap,
    this.onLightbulb,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.5),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lightbulb button
          if (onLightbulb != null)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon:
                    const Icon(Icons.lightbulb, color: AppTheme.accentColor),
                onPressed: onLightbulb,
                tooltip: 'Узнать интересное!',
              ),
            )
          else
            const SizedBox(width: 48),

          const Spacer(),

          // Page dots
          _PageDots(total: pages.length, current: currentPage, onDarkBackground: true),

          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// =============================================================================
// Page dots indicator
// =============================================================================
class _PageDots extends StatelessWidget {
  final int total;
  final int current;
  final bool onDarkBackground;

  const _PageDots({
    required this.total,
    required this.current,
    this.onDarkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    // Show max 10 dots, shift window if needed
    const maxDots = 10;
    int start = 0;
    int end = total;

    if (total > maxDots) {
      start = (current - maxDots ~/ 2).clamp(0, total - maxDots);
      end = start + maxDots;
    }

    final inactiveColor = onDarkBackground
        ? Colors.white.withValues(alpha: 0.4)
        : AppTheme.textLight.withValues(alpha: 0.35);
    final ellipsisColor = onDarkBackground
        ? Colors.white54
        : AppTheme.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (start > 0)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text('...',
                style: TextStyle(color: ellipsisColor, fontSize: 10)),
          ),
        for (int i = start; i < end; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: i == current ? 20 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: i == current
                  ? AppTheme.primaryColor
                  : inactiveColor,
            ),
          ),
        if (end < total)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text('...',
                style: TextStyle(color: ellipsisColor, fontSize: 10)),
          ),
      ],
    );
  }
}
