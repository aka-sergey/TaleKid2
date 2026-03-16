import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../config/ui_assets.dart';
import '../../models/story.dart';
import '../../providers/story_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/shimmer_loading.dart';

/// Library screen — grid of completed stories with rename / delete.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(storiesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: storiesAsync.when(
          data: (stories) {
            if (stories.isEmpty) {
              return _EmptyLibrary();
            }
            return RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: () => ref.read(storiesProvider.notifier).refresh(),
              child: CustomScrollView(
                slivers: [
                  // Custom header
                  SliverToBoxAdapter(
                      child: _LibraryHeader(count: stories.length)),
                  // Grid
                  _StoryGrid(stories: stories),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            );
          },
          loading: () => const _LoadingSkeleton(),
          error: (e, _) => _ErrorState(
            error: e,
            onRetry: () => ref.invalidate(storiesProvider),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Library Header
// =============================================================================
class _LibraryHeader extends StatelessWidget {
  final int count;
  const _LibraryHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.go(AppRoutes.home),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.fillColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back,
                      size: 20, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Библиотека', style: AppTheme.heading(size: 22)),
                  const SizedBox(height: 2),
                  Text(
                    '$count ${_pluralStories(count)}',
                    style: AppTheme.body(
                      size: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go(AppRoutes.wizard),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 18, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'Новая',
                        style: GoogleFonts.comfortaa(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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

  String _pluralStories(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'сказка';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
      return 'сказки';
    }
    return 'сказок';
  }
}

// =============================================================================
// Story Grid
// =============================================================================
class _StoryGrid extends ConsumerWidget {
  final List<StoryModel> stories;

  const _StoryGrid({required this.stories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1000
        ? 4
        : screenWidth > 700
            ? 3
            : 2;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.68,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _StoryCard(story: stories[index]),
          childCount: stories.length,
        ),
      ),
    );
  }
}

// =============================================================================
// Story Card — with hover effect
// =============================================================================
class _StoryCard extends ConsumerStatefulWidget {
  final StoryModel story;

  const _StoryCard({required this.story});

  @override
  ConsumerState<_StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends ConsumerState<_StoryCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovering ? -4 : 0, 0),
        child: GestureDetector(
          onTap: widget.story.isCompleted
              ? () => context.go(
                    AppRoutes.storyReader
                        .replaceAll(':id', widget.story.id),
                  )
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.glassLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.glassBorder, width: 0.5),
              boxShadow: _hovering
                  ? AppTheme.cardShadowHover
                  : AppTheme.cardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cover image
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.story.coverImageUrl != null &&
                          widget.story.coverImageUrl!.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: widget.story.coverImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _PlaceholderCover(
                              title: widget.story.displayTitle),
                          errorWidget: (_, __, ___) => _PlaceholderCover(
                              title: widget.story.displayTitle),
                        )
                      else
                        _PlaceholderCover(
                            title: widget.story.displayTitle),

                      // Status badge
                      if (!widget.story.isCompleted)
                        Positioned(
                          top: 8,
                          left: 8,
                          child:
                              _StatusBadge(status: widget.story.status),
                        ),

                      // Popup menu
                      Positioned(
                        top: 6,
                        right: 6,
                        child: _CardMenu(story: widget.story),
                      ),
                    ],
                  ),
                ),

                // Title & date
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.story.displayTitle,
                          style: GoogleFonts.comfortaa(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          DateFormat('d MMM yyyy', 'ru')
                              .format(widget.story.createdAt),
                          style: GoogleFonts.nunitoSans(
                            fontSize: 11,
                            color: AppTheme.textLight,
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
    );
  }
}

// =============================================================================
// Card popup menu — rename, delete
// =============================================================================
class _CardMenu extends ConsumerWidget {
  final StoryModel story;

  const _CardMenu({required this.story});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.more_vert, color: Colors.white, size: 16),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      onSelected: (value) async {
        switch (value) {
          case 'rename':
            await _showRenameDialog(context, ref);
          case 'delete':
            await _showDeleteDialog(context, ref);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: AppTheme.textSecondary),
              SizedBox(width: 8),
              Text('Переименовать'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
              SizedBox(width: 8),
              Text('Удалить', style: TextStyle(color: AppTheme.errorColor)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: story.displayTitle);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Переименовать', style: AppTheme.heading(size: 20)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(
            hintText: 'Название сказки',
            counterText: '',
          ),
          onSubmitted: (val) => Navigator.pop(ctx, val.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      try {
        await ref
            .read(storiesProvider.notifier)
            .updateTitle(story.id, result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Название обновлено'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      }
    }
    controller.dispose();
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Удалить сказку?', style: AppTheme.heading(size: 20)),
        content: Text(
          'Сказка "${story.displayTitle}" будет удалена навсегда. '
          'Это действие нельзя отменить.',
          style: AppTheme.body(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await ref.read(storiesProvider.notifier).deleteStory(story.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Сказка удалена'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления: $e')),
          );
        }
      }
    }
  }
}

// =============================================================================
// Status badge
// =============================================================================
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'generating' => ('Создаётся...', AppTheme.warningColor),
      'draft' => ('Черновик', AppTheme.textLight),
      'failed' => ('Ошибка', AppTheme.errorColor),
      _ => (status, AppTheme.textLight),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunitoSans(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =============================================================================
// Placeholder cover
// =============================================================================
class _PlaceholderCover extends StatelessWidget {
  final String? title;
  const _PlaceholderCover({this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1A40), // deep indigo
            Color(0xFF2A2050), // purple night
            Color(0xFF2A1A35), // dark rose
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.auto_stories,
                  size: 28, color: AppTheme.primaryColor),
            ),
            if (title != null) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  title!,
                  style: GoogleFonts.comfortaa(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Empty state with illustration
// =============================================================================
class _EmptyLibrary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: CachedNetworkImage(
                    imageUrl: UiAssets.empty_library,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.library_books,
                          size: 56, color: AppTheme.primaryLight),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.library_books,
                          size: 56, color: AppTheme.primaryLight),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Библиотека пуста',
                style: AppTheme.heading(size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'Создайте свою первую сказку!',
                style: AppTheme.body(
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              GradientButton(
                text: 'Создать сказку',
                icon: Icons.auto_stories,
                onPressed: () => context.go(AppRoutes.wizard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Error state
// =============================================================================
class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
            Text(
              'Не удалось загрузить библиотеку',
              style: AppTheme.heading(size: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text('$error',
                textAlign: TextAlign.center,
                style: AppTheme.body(color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            GradientButton(
              text: 'Повторить',
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Loading skeleton (shimmer)
// =============================================================================
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1000
        ? 4
        : screenWidth > 700
            ? 3
            : 2;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.68,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => const ShimmerCard(
          height: double.infinity,
          borderRadius: 20,
        ),
      ),
    );
  }
}
