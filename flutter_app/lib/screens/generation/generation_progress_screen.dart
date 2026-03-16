import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../config/ui_assets.dart';
import '../../providers/generation_provider.dart';
import '../../providers/story_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/title_dialog.dart';

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

/// Pipeline stages for the timeline display.
const _pipelineStages = [
  _Stage('Анализ фото', Icons.camera_alt_outlined, 5),
  _Stage('Паспорта персонажей', Icons.description_outlined, 10),
  _Stage('Написание текста', Icons.edit_note, 30),
  _Stage('Декомпозиция сцен', Icons.grid_view, 35),
  _Stage('Референсы', Icons.portrait_outlined, 45),
  _Stage('Иллюстрации', Icons.palette_outlined, 75),
  _Stage('Образование', Icons.school_outlined, 85),
  _Stage('Название', Icons.title, 90),
  _Stage('Финализация', Icons.check_circle_outline, 100),
];

class _Stage {
  final String label;
  final IconData icon;
  final int endPct;
  const _Stage(this.label, this.icon, this.endPct);
}

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
  bool _completionHandled = false;

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

  int _currentStageIndex(int pct) {
    for (int i = 0; i < _pipelineStages.length; i++) {
      if (pct <= _pipelineStages[i].endPct) return i;
    }
    return _pipelineStages.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(generationJobProvider(widget.jobId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: jobAsync.when(
          data: (jobState) {
            final job = jobState.job;

            // On completion: show title dialog, then navigate to reader
            if (job.isCompleted && !_completionHandled) {
              _completionHandled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!mounted) return;
                final chosenTitle = await TitleDialog.show(
                  context,
                  suggestedTitle: job.storyTitle,
                  storyId: job.storyId,
                );
                if (chosenTitle != null && mounted) {
                  await ref
                      .read(storiesProvider.notifier)
                      .updateTitle(job.storyId, chosenTitle);
                }
                if (mounted) {
                  context.go(
                    AppRoutes.storyReader.replaceAll(':id', job.storyId),
                  );
                }
              });
            }

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top bar with back
                      Row(
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
                          const Spacer(),
                          Text(
                            'Создание сказки',
                            style: AppTheme.heading(size: 18),
                          ),
                          const Spacer(),
                          const SizedBox(width: 40),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Processing state
                      if (job.isProcessing) ...[
                        // Custom progress ring with illustration
                        _buildProgressRing(job.progressPct),
                        const SizedBox(height: 24),

                        // Percentage
                        Text(
                          '${job.progressPct}%',
                          style: GoogleFonts.comfortaa(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Server status
                        if (job.statusMessage != null)
                          Text(
                            job.statusMessage!,
                            style: AppTheme.body(
                              size: 15,
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 16),

                        // Funny rotating message
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            _funnyStatuses[_funnyStatusIndex],
                            key: ValueKey(_funnyStatusIndex),
                            style: GoogleFonts.nunitoSans(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: AppTheme.primaryLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Pipeline timeline
                        _buildTimeline(job.progressPct),
                        const SizedBox(height: 24),

                        // Timer
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.fillColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined,
                                  size: 16, color: AppTheme.textLight),
                              const SizedBox(width: 6),
                              Text(
                                _formatElapsed(),
                                style: AppTheme.body(
                                  size: 14,
                                  weight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Cancel button
                        TextButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Text('Отменить?',
                                    style: AppTheme.heading(size: 20)),
                                content: Text(
                                  'Вы уверены, что хотите отменить создание сказки?',
                                  style: AppTheme.body(
                                      color: AppTheme.textSecondary),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Нет'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.errorColor,
                                    ),
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
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textLight,
                          ),
                          child: const Text('Отменить генерацию'),
                        ),
                      ],

                      // Completed state
                      if (job.isCompleted) ...[
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.successColor.withValues(alpha: 0.2),
                                AppTheme.successColor.withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            size: 64,
                            color: AppTheme.successColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Сказка готова!',
                          style: AppTheme.heading(
                            size: 28,
                            color: AppTheme.successColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Переходим к чтению...',
                          style: AppTheme.body(color: AppTheme.textSecondary),
                        ),
                      ],

                      // Failed state
                      if (job.isFailed) ...[
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.errorColor.withValues(alpha: 0.1),
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppTheme.errorColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Не удалось создать сказку',
                          style: AppTheme.heading(
                            size: 22,
                            color: AppTheme.errorColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        if (job.errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              job.errorMessage!,
                              style: AppTheme.body(
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 28),
                        GradientButton(
                          text: 'Попробовать снова',
                          icon: Icons.refresh,
                          onPressed: () => context.go(AppRoutes.wizard),
                        ),
                        const SizedBox(height: 12),
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
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
          error: (e, _) => Center(
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
                  Text(
                    'Ошибка загрузки статуса',
                    style: AppTheme.heading(size: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$e',
                    style: AppTheme.body(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    text: 'Повторить',
                    icon: Icons.refresh,
                    onPressed: () =>
                        ref.invalidate(generationJobProvider(widget.jobId)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Custom progress ring
  // ---------------------------------------------------------------------------
  Widget _buildProgressRing(int pct) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: 180,
            height: 180,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 10,
              color: AppTheme.fillColor,
              strokeCap: StrokeCap.round,
            ),
          ),
          // Progress arc
          SizedBox(
            width: 180,
            height: 180,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CircularProgressIndicator(
                  value: pct / 100.0,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.lerp(
                      AppTheme.primaryColor,
                      AppTheme.secondaryColor,
                      _pulseController.value * 0.3,
                    )!,
                  ),
                );
              },
            ),
          ),
          // Center illustration
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.95 + (_pulseController.value * 0.05),
                child: child,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: SizedBox(
                width: 120,
                height: 120,
                child: CachedNetworkImage(
                  imageUrl: UiAssets.generation_magic,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
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
                        size: 48,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryLight.withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.auto_stories,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pipeline timeline
  // ---------------------------------------------------------------------------
  Widget _buildTimeline(int pct) {
    final currentIdx = _currentStageIndex(pct);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glassBorder, width: 0.5),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: List.generate(_pipelineStages.length, (i) {
          final stage = _pipelineStages[i];
          final isDone = i < currentIdx;
          final isActive = i == currentIdx;

          return Padding(
            padding: EdgeInsets.only(
              bottom: i < _pipelineStages.length - 1 ? 4 : 0,
            ),
            child: Row(
              children: [
                // Icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppTheme.successColor
                        : isActive
                            ? AppTheme.primaryColor
                            : AppTheme.fillColor,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check,
                            size: 14, color: Colors.white)
                        : isActive
                            ? SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(stage.icon,
                                size: 14, color: AppTheme.textLight),
                  ),
                ),
                const SizedBox(width: 12),
                // Label
                Expanded(
                  child: Text(
                    stage.label,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w400,
                      color: isDone
                          ? AppTheme.successColor
                          : isActive
                              ? AppTheme.textPrimary
                              : AppTheme.textLight,
                    ),
                  ),
                ),
                // Percentage marker
                if (isDone)
                  Text(
                    '${stage.endPct}%',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 11,
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
