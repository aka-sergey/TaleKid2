import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../models/story.dart';
import '../../providers/story_provider.dart';

/// Library screen — grid of completed stories with rename / delete.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(storiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Библиотека'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: () => ref.read(storiesProvider.notifier).refresh(),
          ),
        ],
      ),
      body: storiesAsync.when(
        data: (stories) {
          if (stories.isEmpty) {
            return _EmptyLibrary();
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(storiesProvider.notifier).refresh(),
            child: _StoryGrid(stories: stories),
          );
        },
        loading: () => const _LoadingSkeleton(),
        error: (e, _) => _ErrorState(
          error: e,
          onRetry: () => ref.invalidate(storiesProvider),
        ),
      ),
    );
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
    final crossAxisCount = screenWidth > 900
        ? 4
        : screenWidth > 600
            ? 3
            : 2;

    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.72,
        crossAxisSpacing: AppTheme.spacingMd,
        mainAxisSpacing: AppTheme.spacingMd,
      ),
      itemCount: stories.length,
      itemBuilder: (context, index) => _StoryCard(story: stories[index]),
    );
  }
}

// =============================================================================
// Story Card
// =============================================================================
class _StoryCard extends ConsumerWidget {
  final StoryModel story;

  const _StoryCard({required this.story});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: story.isCompleted
            ? () => context.go(
                  AppRoutes.storyReader.replaceAll(':id', story.id),
                )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  if (story.coverImageUrl != null)
                    CachedNetworkImage(
                      imageUrl: story.coverImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppTheme.primaryLight.withValues(alpha: 0.1),
                        child: const Center(
                          child: Icon(Icons.auto_stories,
                              size: 40, color: AppTheme.primaryLight),
                        ),
                      ),
                      errorWidget: (_, __, ___) => _PlaceholderCover(),
                    )
                  else
                    _PlaceholderCover(),

                  // Status badge
                  if (!story.isCompleted)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _StatusBadge(status: story.status),
                    ),

                  // Popup menu
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _CardMenu(story: story),
                  ),
                ],
              ),
            ),

            // Title & date
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: AppTheme.spacingXs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      story.displayTitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('d MMM yyyy', 'ru').format(story.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
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
        title: const Text('Переименовать'),
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
        await ref.read(storiesProvider.notifier).updateTitle(story.id, result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Название обновлено')),
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
        title: const Text('Удалить сказку?'),
        content: Text(
          'Сказка "${story.displayTitle}" будет удалена навсегда. '
          'Это действие нельзя отменить.',
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
            const SnackBar(content: Text('Сказка удалена')),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: const TextStyle(
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
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryLight.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.auto_stories, size: 48, color: AppTheme.primaryLight),
      ),
    );
  }
}

// =============================================================================
// Empty state
// =============================================================================
class _EmptyLibrary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.library_books,
                size: 56,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Библиотека пуста',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Создайте свою первую сказку!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.wizard),
              icon: const Icon(Icons.auto_stories),
              label: const Text('Создать сказку'),
            ),
          ],
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
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppTheme.errorColor),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Не удалось загрузить библиотеку',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
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
    final crossAxisCount = screenWidth > 900
        ? 4
        : screenWidth > 600
            ? 3
            : 2;

    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.72,
          crossAxisSpacing: AppTheme.spacingMd,
          mainAxisSpacing: AppTheme.spacingMd,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Card(
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(color: Colors.white),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        width: 80,
                        color: Colors.white,
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
