import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
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
        const SnackBar(content: Text('Генерируем PDF...')),
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
        const SnackBar(content: Text('Ссылка скопирована!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final storyAsync = ref.watch(storyDetailProvider(widget.storyId));

    return storyAsync.when(
      data: (story) {
        // Show title dialog once on first load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showTitleDialog(story);
        });

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
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'Загружаем сказку...',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Ошибка')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: AppTheme.errorColor),
                const SizedBox(height: AppTheme.spacingMd),
                Text('Не удалось загрузить сказку',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppTheme.spacingSm),
                Text('$e', textAlign: TextAlign.center),
                const SizedBox(height: AppTheme.spacingLg),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(storyDetailProvider(widget.storyId)),
                  child: const Text('Повторить'),
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.library),
        ),
        title: Text(story.displayTitle),
        actions: [
          // Page indicator
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_currentPage + 1} / ${pages.length}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          // Lightbulb button
          if (page.educationalContent != null)
            IconButton(
              icon: const Icon(Icons.lightbulb, color: AppTheme.accentColor),
              tooltip: 'Образовательный контент',
              onPressed: () =>
                  EducationalPopup.show(context, page.educationalContent!),
            ),
          // PDF export
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Скачать PDF',
            onPressed: () => _exportPdf(story),
          ),
          // Share
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Поделиться',
            onPressed: () => _shareStory(story),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 900 : double.infinity),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              children: [
                // Image — 80-90% viewport height
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: page.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: page.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppTheme.primaryLight.withValues(alpha: 0.1),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppTheme.primaryLight.withValues(alpha: 0.1),
                              child: const Icon(Icons.broken_image,
                                  size: 64, color: AppTheme.textLight),
                            ),
                          )
                        : Container(
                            color: AppTheme.primaryLight.withValues(alpha: 0.1),
                            child: const Icon(Icons.image,
                                size: 64, color: AppTheme.textLight),
                          ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Text content
                if (page.textContent != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd),
                    child: Text(
                      page.textContent!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 18,
                            height: 1.7,
                            color: AppTheme.textPrimary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: AppTheme.spacingXl),

                // Navigation arrows
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filled(
                      onPressed: _currentPage > 0
                          ? () => setState(() => _currentPage--)
                          : null,
                      icon: const Icon(Icons.arrow_back_ios_new),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        disabledBackgroundColor:
                            AppTheme.textLight.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingXl),
                    // Page dots (limited to 10 visible)
                    _PageDots(
                      total: pages.length,
                      current: _currentPage,
                    ),
                    const SizedBox(width: AppTheme.spacingXl),
                    IconButton.filled(
                      onPressed: _currentPage < pages.length - 1
                          ? () => setState(() => _currentPage++)
                          : null,
                      icon: const Icon(Icons.arrow_forward_ios),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        disabledBackgroundColor:
                            AppTheme.textLight.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сказка')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book, size: 64, color: AppTheme.textLight),
            const SizedBox(height: AppTheme.spacingMd),
            Text('Страницы ещё не готовы',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingLg),
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
// Mobile page view — fullscreen image + text overlay
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
            child:
                const Icon(Icons.image, size: 64, color: Colors.white24),
          ),

        // Text overlay at bottom
        if (page.textContent != null)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Text(
                page.textContent!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.6),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onPdf != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white70),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              '${currentPage + 1}/$totalPages',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
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
            Colors.black.withValues(alpha: 0.6),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lightbulb button
          if (onLightbulb != null)
            IconButton(
              icon: const Icon(Icons.lightbulb, color: AppTheme.accentColor),
              onPressed: onLightbulb,
              tooltip: 'Узнать интересное!',
            )
          else
            const SizedBox(width: 48),

          const Spacer(),

          // Page dots
          _PageDots(total: pages.length, current: currentPage),

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

  const _PageDots({required this.total, required this.current});

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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (start > 0)
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Text('...', style: TextStyle(color: Colors.white54, fontSize: 10)),
          ),
        for (int i = start; i < end; i++)
          Container(
            width: i == current ? 10 : 6,
            height: i == current ? 10 : 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == current
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
            ),
          ),
        if (end < total)
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text('...', style: TextStyle(color: Colors.white54, fontSize: 10)),
          ),
      ],
    );
  }
}
