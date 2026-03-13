import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../providers/generation_provider.dart';

/// Funny Russian status messages that rotate while generating.
const _funnyStatuses = [
  'Волшебные чернила готовятся...',
  'Единорог вдохновляет художника...',
  'Феи раскрашивают картинки...',
  'Гномы пишут сюжет...',
  'Дракон проверяет орфографию...',
  'Звёзды освещают страницы...',
  'Эльфы подбирают слова...',
  'Мудрая сова проверяет факты...',
  'Радужные краски смешиваются...',
  'Волшебная палочка рисует...',
  'Пегас несёт вдохновение...',
  'Сказочные буквы выстраиваются...',
  'Облака принимают форму персонажей...',
  'Лунный свет рисует тени...',
  'Волшебный ветер переворачивает страницы...',
];

/// Screen that displays generation progress with polling.
class GenerationProgressScreen extends ConsumerStatefulWidget {
  final String jobId;

  const GenerationProgressScreen({super.key, required this.jobId});

  @override
  ConsumerState<GenerationProgressScreen> createState() =>
      _GenerationProgressScreenState();
}

class _GenerationProgressScreenState
    extends ConsumerState<GenerationProgressScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _rotateController;
  final _random = Random();
  int _funnyStatusIndex = 0;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _funnyStatusIndex = _random.nextInt(_funnyStatuses.length);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Rotate funny status every 5 seconds
    _scheduleFunnyStatusRotation();
  }

  void _scheduleFunnyStatusRotation() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _funnyStatusIndex =
              (_funnyStatusIndex + 1) % _funnyStatuses.length;
        });
        _scheduleFunnyStatusRotation();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  String _formatElapsed() {
    if (_startTime == null) return '';
    final elapsed = DateTime.now().difference(_startTime!);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(generationJobProvider(widget.jobId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создание сказки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: jobAsync.when(
        data: (jobState) {
          final job = jobState.job;

          // Auto-navigate to reader on completion
          if (job.isCompleted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.go(
                  AppRoutes.storyReader.replaceAll(':id', job.storyId),
                );
              }
            });
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated icon
                    if (job.isProcessing) _buildAnimatedIcon(),
                    if (job.isCompleted) _buildCompletedIcon(),
                    if (job.isFailed) _buildFailedIcon(),
                    const SizedBox(height: AppTheme.spacingXl),

                    // Progress percentage
                    if (job.isProcessing) ...[
                      Text(
                        '${job.progressPct}%',
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),

                      // Progress bar
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                        child: LinearProgressIndicator(
                          value: job.progressPct / 100.0,
                          minHeight: 12,
                          backgroundColor:
                              AppTheme.primaryLight.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),

                      // Status message from server
                      if (job.statusMessage != null)
                        Text(
                          job.statusMessage!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: AppTheme.spacingMd),

                      // Funny rotating status
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: Text(
                          _funnyStatuses[_funnyStatusIndex],
                          key: ValueKey(_funnyStatusIndex),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppTheme.primaryLight,
                                fontStyle: FontStyle.italic,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),

                      // Timer
                      Text(
                        _formatElapsed(),
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textLight,
                                ),
                      ),
                      const SizedBox(height: AppTheme.spacingXl),

                      // Cancel button
                      TextButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Отменить?'),
                              content: const Text(
                                  'Вы уверены, что хотите отменить создание сказки?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('Нет'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  child: const Text('Да, отменить'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && mounted) {
                            ref
                                .read(generationJobProvider(widget.jobId)
                                    .notifier)
                                .cancelJob();
                          }
                        },
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Отменить'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                        ),
                      ),
                    ],

                    // Completed state
                    if (job.isCompleted) ...[
                      Text(
                        'Сказка готова!',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w700,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        'Переходим к чтению...',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],

                    // Failed state
                    if (job.isFailed) ...[
                      Text(
                        'Не удалось создать сказку',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.w700,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      if (job.errorMessage != null)
                        Text(
                          job.errorMessage!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: AppTheme.spacingXl),
                      ElevatedButton.icon(
                        onPressed: () => context.go(AppRoutes.wizard),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Попробовать снова'),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.home),
                        child: const Text('На главную'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: AppTheme.errorColor),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  'Ошибка загрузки статуса',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text('$e'),
                const SizedBox(height: AppTheme.spacingLg),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(generationJobProvider(widget.jobId)),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (_pulseController.value * 0.2),
          child: child,
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primaryLight.withValues(alpha: 0.15),
        ),
        child: AnimatedBuilder(
          animation: _rotateController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotateController.value * 2 * pi,
              child: child,
            );
          },
          child: const Icon(
            Icons.auto_stories,
            size: 56,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.successColor.withValues(alpha: 0.15),
      ),
      child: const Icon(
        Icons.check_circle,
        size: 64,
        color: AppTheme.successColor,
      ),
    );
  }

  Widget _buildFailedIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.errorColor.withValues(alpha: 0.15),
      ),
      child: const Icon(
        Icons.error_outline,
        size: 64,
        color: AppTheme.errorColor,
      ),
    );
  }
}
