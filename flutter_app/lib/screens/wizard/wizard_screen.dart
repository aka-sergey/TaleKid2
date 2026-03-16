import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../config/ui_assets.dart';
import '../../models/catalog.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/character_provider.dart';
import '../../providers/generation_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/shimmer_loading.dart';
import 'character_create_dialog.dart';

// ── Slug → UiAssets mappings ────────────────────────────────────────────
const _genreAssets = <String, String>{
  'adventure': UiAssets.adventure,
  'fairy-tale': UiAssets.fairy_tale,
  'educational': UiAssets.educational,
  'friendship': UiAssets.friendship,
  'funny': UiAssets.funny,
  'bedtime': UiAssets.bedtime,
  // Forward-compat: if DB is re-seeded with expanded catalog
  'humor': UiAssets.funny,
  'science-adventure': UiAssets.educational,
  'family-stories': UiAssets.bedtime,
};

const _worldAssets = <String, String>{
  'enchanted-forest': UiAssets.magic_forest,
  'space': UiAssets.space,
  'underwater': UiAssets.underwater,
  'medieval-kingdom': UiAssets.medieval_kingdom,
  'modern-city': UiAssets.modern_city,
  'dinosaur-world': UiAssets.dinosaur_world,
  // Forward-compat: if DB is re-seeded with expanded catalog
  'outer-space': UiAssets.space,
  'underwater-kingdom': UiAssets.underwater,
  'future-city': UiAssets.modern_city,
};

const _ageAssets = <String, String>{
  '3-5': UiAssets.age_3_5,
  '6-8': UiAssets.age_6_8,
  '9-12': UiAssets.age_9_12,
};

// ═════════════════════════════════════════════════════════════════════════
// Wizard Screen
// ═════════════════════════════════════════════════════════════════════════

class WizardScreen extends ConsumerStatefulWidget {
  const WizardScreen({super.key});

  @override
  ConsumerState<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends ConsumerState<WizardScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  final Set<String> _selectedCharacterIds = {};
  String _ageRange = '3-5';
  double _educationLevel = 0.5;
  int? _selectedGenreId;
  int? _selectedWorldId;
  int? _selectedBaseTaleId;
  int _pageCount = 10;
  int _readingDuration = 10;

  bool get _canProceedStep1 => _selectedCharacterIds.isNotEmpty;
  bool get _canProceedStep2 =>
      _selectedGenreId != null && _selectedWorldId != null;
  bool get _canSubmit => _canProceedStep1 && _canProceedStep2;

  void _nextStep() {
    if (_currentStep < 2) setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _submit() async {
    if (!_canSubmit || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(generationServiceProvider);
      final job = await service.createGeneration(
        characterIds: _selectedCharacterIds.toList(),
        genreId: _selectedGenreId!,
        worldId: _selectedWorldId!,
        baseTaleId: _selectedBaseTaleId,
        ageRange: _ageRange,
        educationLevel: _educationLevel,
        pageCount: _pageCount,
        readingDurationMinutes: _readingDuration,
      );
      if (mounted) {
        context.go(
            AppRoutes.generationProgress.replaceAll(':jobId', job.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _circleBtn(Icons.close_rounded,
                      () => context.go(AppRoutes.home)),
                  const Spacer(),
                  Text('Создать сказку',
                      style: AppTheme.heading(size: 18)),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            // ── Step indicator ───────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
              child: _StepIndicator(currentStep: _currentStep),
            ),
            // ── Content ──────────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: _buildStep(),
              ),
            ),
            // ── Bottom nav ───────────────────────────────────────
            _BottomNav(
              currentStep: _currentStep,
              canProceed: _currentStep == 0
                  ? _canProceedStep1
                  : _currentStep == 1
                      ? _canProceedStep2
                      : _canSubmit,
              isSubmitting: _isSubmitting,
              onBack: _currentStep > 0 ? _prevStep : null,
              onNext: _currentStep < 2 ? _nextStep : null,
              onSubmit: _currentStep == 2 ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _Step1Characters(
          key: const ValueKey('s1'),
          selectedIds: _selectedCharacterIds,
          onSelectionChanged: (ids) => setState(() {
            _selectedCharacterIds
              ..clear()
              ..addAll(ids);
          }),
        );
      case 1:
        return _Step2Settings(
          key: const ValueKey('s2'),
          ageRange: _ageRange,
          educationLevel: _educationLevel,
          selectedGenreId: _selectedGenreId,
          selectedWorldId: _selectedWorldId,
          selectedBaseTaleId: _selectedBaseTaleId,
          onAgeRangeChanged: (v) => setState(() => _ageRange = v),
          onEducationLevelChanged: (v) =>
              setState(() => _educationLevel = v),
          onGenreChanged: (v) => setState(() => _selectedGenreId = v),
          onWorldChanged: (v) => setState(() => _selectedWorldId = v),
          onBaseTaleChanged: (v) =>
              setState(() => _selectedBaseTaleId = v),
        );
      case 2:
        return _Step3Format(
          key: const ValueKey('s3'),
          pageCount: _pageCount,
          readingDuration: _readingDuration,
          onPageCountChanged: (v) => setState(() => _pageCount = v),
          onReadingDurationChanged: (v) =>
              setState(() => _readingDuration = v),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.fillColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppTheme.textSecondary),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════
// Step Indicator
// ═════════════════════════════════════════════════════════════════════════

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  static const _icons = [Icons.person, Icons.tune, Icons.menu_book];
  static const _labels = ['Персонажи', 'Настройки', 'Формат'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        if (i.isOdd) {
          final done = i ~/ 2 < currentStep;
          return Expanded(
            child: Container(
              height: 2.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: done
                    ? const LinearGradient(colors: [
                        AppTheme.successColor,
                        AppTheme.primaryColor
                      ])
                    : null,
                color: done ? null : AppTheme.borderColor,
              ),
            ),
          );
        }
        final step = i ~/ 2;
        final active = step == currentStep;
        final done = step < currentStep;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? AppTheme.successColor
                    : active
                        ? AppTheme.primaryColor
                        : AppTheme.fillColor,
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor
                              .withValues(alpha: 0.35),
                          blurRadius: 12,
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check_rounded,
                        size: 18, color: Colors.white)
                    : Icon(_icons[step],
                        size: 18,
                        color: active
                            ? Colors.white
                            : AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _labels[step],
              style: AppTheme.body(
                size: 11,
                weight: active ? FontWeight.w700 : FontWeight.w500,
                color:
                    active ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Step 1 — Characters
// ═════════════════════════════════════════════════════════════════════════

class _Step1Characters extends ConsumerWidget {
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onSelectionChanged;

  const _Step1Characters({
    super.key,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charsAsync = ref.watch(charactersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Выберите персонажей',
                  style: AppTheme.heading(size: 22)),
              const SizedBox(height: 4),
              Text(
                  'Выберите одного или нескольких персонажей для вашей сказки',
                  style: AppTheme.body(
                      size: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 20),

              // Create button
              AppCard(
                onTap: () => CharacterCreateDialog.show(context,
                    onSaved: () => ref.invalidate(charactersProvider)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline,
                        color: AppTheme.primaryColor, size: 22),
                    const SizedBox(width: 12),
                    Text('Создать персонажа',
                        style: AppTheme.body(
                            size: 15,
                            weight: FontWeight.w600,
                            color: AppTheme.primaryColor)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Character list
              charsAsync.when(
                data: (chars) {
                  if (chars.isEmpty) {
                    return _emptyState();
                  }
                  return Column(
                    children: chars.map((c) {
                      final sel = selectedIds.contains(c.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          highlighted: sel,
                          onTap: () {
                            final n = Set<String>.from(selectedIds);
                            sel ? n.remove(c.id) : n.add(c.id);
                            onSelectionChanged(n);
                          },
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              _charAvatar(c),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name,
                                        style: AppTheme.body(
                                            size: 15,
                                            weight: FontWeight.w700)),
                                    const SizedBox(height: 3),
                                    Row(children: [
                                      _badge(c.characterTypeLabel),
                                      if (c.age != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                            '${c.age} ${_ageSuffix(c.age!)}',
                                            style: AppTheme.body(
                                                size: 12,
                                                color: AppTheme
                                                    .textSecondary)),
                                      ],
                                    ]),
                                  ],
                                ),
                              ),
                              AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 200),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: sel
                                      ? AppTheme.primaryColor
                                      : AppTheme.fillColor,
                                  border: sel
                                      ? null
                                      : Border.all(
                                          color: AppTheme.borderColor,
                                          width: 1.5),
                                ),
                                child: sel
                                    ? const Icon(Icons.check_rounded,
                                        size: 16, color: Colors.white)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => Column(
                  children: List.generate(
                      3,
                      (_) => const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: ShimmerCard(height: 72))),
                ),
                error: (e, _) => _ErrorRetry(
                    message: 'Ошибка загрузки: $e',
                    onRetry: () => ref.invalidate(charactersProvider)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(children: [
            Icon(Icons.people_outline,
                size: 64,
                color: AppTheme.textLight.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('У вас пока нет персонажей',
                style: AppTheme.body(
                    size: 15, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text('Создайте хотя бы одного персонажа',
                style:
                    AppTheme.body(size: 13, color: AppTheme.textLight)),
          ]),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════
// Step 2 — Settings
// ═════════════════════════════════════════════════════════════════════════

class _Step2Settings extends ConsumerWidget {
  final String ageRange;
  final double educationLevel;
  final int? selectedGenreId;
  final int? selectedWorldId;
  final int? selectedBaseTaleId;
  final ValueChanged<String> onAgeRangeChanged;
  final ValueChanged<double> onEducationLevelChanged;
  final ValueChanged<int?> onGenreChanged;
  final ValueChanged<int?> onWorldChanged;
  final ValueChanged<int?> onBaseTaleChanged;

  const _Step2Settings({
    super.key,
    required this.ageRange,
    required this.educationLevel,
    required this.selectedGenreId,
    required this.selectedWorldId,
    required this.selectedBaseTaleId,
    required this.onAgeRangeChanged,
    required this.onEducationLevelChanged,
    required this.onGenreChanged,
    required this.onWorldChanged,
    required this.onBaseTaleChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresAsync = ref.watch(genresProvider);
    final worldsAsync = ref.watch(worldsProvider);
    final baseTalesAsync = ref.watch(baseTalesProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    // Genres and worlds expand to 70% of screen width (min 400, max 1200)
    final wideMaxWidth = (screenWidth * 0.70).clamp(400.0, 1200.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Narrow controls: Age + Education ───────────────────────
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Возрастная группа',
                    style: AppTheme.heading(size: 17)),
                const SizedBox(height: 12),
                _AgeCards(
                    selected: ageRange, onChanged: onAgeRangeChanged),
                const SizedBox(height: 28),
                Text('Уровень образовательности',
                    style: AppTheme.heading(size: 17)),
                const SizedBox(height: 12),
                _EduSlider(
                    value: educationLevel,
                    onChanged: onEducationLevelChanged),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Wide: Genres ────────────────────────────────────────────
          SizedBox(
            width: wideMaxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Жанр *', style: AppTheme.heading(size: 17)),
                const SizedBox(height: 12),
                genresAsync.when(
                  data: (g) => _GenreCards(
                      genres: g,
                      selectedId: selectedGenreId,
                      onSelected: onGenreChanged),
                  loading: () => const _ShimmerRow(),
                  error: (_, __) => _ErrorRetry(
                      message: 'Ошибка загрузки жанров',
                      onRetry: () => ref.invalidate(genresProvider)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Wide: Worlds ────────────────────────────────────────────
          SizedBox(
            width: wideMaxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Мир *', style: AppTheme.heading(size: 17)),
                const SizedBox(height: 12),
                worldsAsync.when(
                  data: (w) => _WorldGrid(
                      worlds: w,
                      selectedId: selectedWorldId,
                      onSelected: onWorldChanged),
                  loading: () => const _ShimmerRow(),
                  error: (_, __) => _ErrorRetry(
                      message: 'Ошибка загрузки миров',
                      onRetry: () => ref.invalidate(worldsProvider)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Narrow: Base tale ───────────────────────────────────────
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Сказка-основа',
                      style: AppTheme.heading(size: 17)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppTheme.fillColor,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('необязательно',
                        style: AppTheme.body(
                            size: 11, color: AppTheme.textSecondary)),
                  ),
                ]),
                const SizedBox(height: 12),
                baseTalesAsync.when(
                  data: (t) => _BaseTaleSel(
                      tales: t,
                      selectedId: selectedBaseTaleId,
                      onSelected: onBaseTaleChanged),
                  loading: () => const _ShimmerRow(),
                  error: (_, __) => _ErrorRetry(
                      message: 'Ошибка загрузки сказок',
                      onRetry: () => ref.invalidate(baseTalesProvider)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Step 3 — Format
// ═════════════════════════════════════════════════════════════════════════

class _Step3Format extends StatelessWidget {
  final int pageCount;
  final int readingDuration;
  final ValueChanged<int> onPageCountChanged;
  final ValueChanged<int> onReadingDurationChanged;

  const _Step3Format({
    super.key,
    required this.pageCount,
    required this.readingDuration,
    required this.onPageCountChanged,
    required this.onReadingDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Формат сказки', style: AppTheme.heading(size: 22)),
              const SizedBox(height: 4),
              Text('Настройте длину и время чтения',
                  style: AppTheme.body(
                      size: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 28),
              Text('Количество страниц',
                  style: AppTheme.heading(size: 17)),
              const SizedBox(height: 12),
              Slider(
                value: pageCount.toDouble(),
                min: 5,
                max: 30,
                divisions: 25,
                label: '$pageCount',
                onChanged: (v) => onPageCountChanged(v.round()),
              ),
              _PresetRow(
                  values: const [5, 10, 15, 20, 25, 30],
                  selected: pageCount,
                  onSelected: onPageCountChanged),
              const SizedBox(height: 28),
              Text('Время чтения',
                  style: AppTheme.heading(size: 17)),
              const SizedBox(height: 12),
              Slider(
                value: readingDuration.toDouble(),
                min: 5,
                max: 30,
                divisions: 25,
                label: '$readingDuration мин',
                onChanged: (v) =>
                    onReadingDurationChanged(v.round()),
              ),
              _PresetRow(
                  values: const [5, 10, 15, 20, 30],
                  selected: readingDuration,
                  onSelected: onReadingDurationChanged,
                  suffix: ' мин'),
              const SizedBox(height: 28),
              AppCard(
                color: AppTheme.fillColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppTheme.infoColor, size: 20),
                      const SizedBox(width: 8),
                      Text('Параметры сказки',
                          style: AppTheme.body(
                              size: 15, weight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 14),
                    _sRow('Страниц', '$pageCount'),
                    _sRow('Время чтения', '$readingDuration мин'),
                    _sRow('Иллюстраций', '$pageCount'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sRow(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l,
                style: AppTheme.body(
                    size: 14, color: AppTheme.textSecondary)),
            Text(v,
                style:
                    AppTheme.body(size: 14, weight: FontWeight.w700)),
          ],
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ═════════════════════════════════════════════════════════════════════════

class _AgeCards extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _AgeCards({required this.selected, required this.onChanged});

  static const _ranges = [
    ('3-5', '3–5 лет', 'Малыши'),
    ('6-8', '6–8 лет', 'Юные читатели'),
    ('9-12', '9–12 лет', 'Подростки'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _ranges.map((r) {
        final sel = r.$1 == selected;
        final url = _ageAssets[r.$1] ?? '';
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                right: r.$1 != _ranges.last.$1 ? 12 : 0),
            child: GestureDetector(
              onTap: () => onChanged(r.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: sel
                          ? AppTheme.primaryColor
                          : AppTheme.borderColor,
                      width: sel ? 2.5 : 1),
                  boxShadow: sel ? AppTheme.cardShadow : null,
                  color: AppTheme.glassLight,
                ),
                child: Column(children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    child: url.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: url,
                            height: 90,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                height: 90, color: AppTheme.fillColor),
                            errorWidget: (_, __, ___) => Container(
                                height: 90, color: AppTheme.fillColor),
                          )
                        : Container(
                            height: 90, color: AppTheme.fillColor),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(children: [
                      Text(r.$2,
                          style: AppTheme.body(
                              size: 13, weight: FontWeight.w700)),
                      Text(r.$3,
                          style: AppTheme.body(
                              size: 11,
                              color: AppTheme.textSecondary)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EduSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _EduSlider({required this.value, required this.onChanged});

  String get _label {
    if (value < 0.3) return 'Минимум фактов';
    if (value < 0.7) return 'Сбалансировано';
    return 'Максимум обучения';
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Slider(
          value: value,
          min: 0,
          max: 1,
          divisions: 10,
          label: _label,
          onChanged: onChanged),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Развлечение',
                style: AppTheme.body(
                    size: 12, color: AppTheme.textSecondary)),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Container(
                key: ValueKey(_label),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color:
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_label,
                    style: AppTheme.body(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppTheme.primaryColor)),
              ),
            ),
            Text('Обучение',
                style: AppTheme.body(
                    size: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    ]);
  }
}

class _GenreCards extends StatelessWidget {
  final List<Genre> genres;
  final int? selectedId;
  final ValueChanged<int?> onSelected;
  const _GenreCards(
      {required this.genres,
      required this.selectedId,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      // Adaptive columns: ~160px per card, min 3, max 8
      final cols = (box.maxWidth / 160).floor().clamp(3, 8);
      final spacing = 10.0;
      final itemWidth =
          (box.maxWidth - spacing * (cols - 1)) / cols;
      final imageHeight = (itemWidth * 0.55).clamp(70.0, 120.0);

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: genres.map((g) {
          final sel = g.id == selectedId;
          final url = _genreAssets[g.slug] ?? '';
          return GestureDetector(
            onTap: () => onSelected(sel ? null : g.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: itemWidth,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: sel
                        ? AppTheme.primaryColor
                        : AppTheme.borderColor,
                    width: sel ? 2 : 1),
                color: AppTheme.glassLight,
              ),
              child: Column(children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(13)),
                  child: url.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: url,
                          height: imageHeight,
                          width: itemWidth,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              height: imageHeight,
                              color: AppTheme.fillColor),
                          errorWidget: (_, __, ___) => Container(
                              height: imageHeight,
                              color: AppTheme.fillColor),
                        )
                      : Container(
                          height: imageHeight,
                          color: AppTheme.fillColor),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(g.nameRu,
                      style: AppTheme.body(
                          size: 12, weight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
          );
        }).toList(),
      );
    });
  }
}

class _WorldGrid extends StatelessWidget {
  final List<World> worlds;
  final int? selectedId;
  final ValueChanged<int?> onSelected;
  const _WorldGrid(
      {required this.worlds,
      required this.selectedId,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      // Adaptive columns: ~160px per card, min 3, max 8
      final cols = (box.maxWidth / 160).floor().clamp(3, 8);
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: worlds.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85),
        itemBuilder: (_, i) {
          final w = worlds[i];
          final sel = w.id == selectedId;
          final url = _worldAssets[w.slug] ?? '';
          return GestureDetector(
            onTap: () => onSelected(sel ? null : w.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: sel
                  ? (Matrix4.identity()..scale(1.02, 1.02))
                  : Matrix4.identity(),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: sel
                        ? AppTheme.primaryColor
                        : AppTheme.borderColor,
                    width: sel ? 2.5 : 1),
                boxShadow: sel ? AppTheme.cardShadow : null,
                color: AppTheme.glassLight,
              ),
              child: Column(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    child: url.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: url,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: AppTheme.fillColor),
                            errorWidget: (_, __, ___) =>
                                Container(color: AppTheme.fillColor),
                          )
                        : Container(color: AppTheme.fillColor),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(w.nameRu,
                      style: AppTheme.body(
                          size: 13, weight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
          );
        },
      );
    });
  }
}

class _BaseTaleSel extends StatelessWidget {
  final List<BaseTale> tales;
  final int? selectedId;
  final ValueChanged<int?> onSelected;
  const _BaseTaleSel(
      {required this.tales,
      required this.selectedId,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChoiceChip(
          label: const Text('Оригинальный сюжет'),
          avatar: const Icon(Icons.auto_awesome, size: 18),
          selected: selectedId == null,
          onSelected: (_) => onSelected(null),
          showCheckmark: false,
          selectedColor: AppTheme.accentLight.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tales.map((t) {
            final sel = t.id == selectedId;
            return ChoiceChip(
              label: Text(t.nameRu),
              selected: sel,
              onSelected: (_) => onSelected(sel ? null : t.id),
              showCheckmark: false,
              selectedColor:
                  AppTheme.primaryLight.withValues(alpha: 0.25),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PresetRow extends StatelessWidget {
  final List<int> values;
  final int selected;
  final ValueChanged<int> onSelected;
  final String suffix;
  const _PresetRow(
      {required this.values,
      required this.selected,
      required this.onSelected,
      this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: values.map((v) {
        final sel = v == selected;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () => onSelected(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel
                    ? AppTheme.primaryColor
                    : AppTheme.fillColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$v$suffix',
                  style: AppTheme.body(
                      size: 13,
                      weight: FontWeight.w600,
                      color: sel
                          ? Colors.white
                          : AppTheme.textSecondary)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Bottom Navigation ───────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentStep;
  final bool canProceed;
  final bool isSubmitting;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;

  const _BottomNav({
    required this.currentStep,
    required this.canProceed,
    required this.isSubmitting,
    this.onBack,
    this.onNext,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 14,
          bottom: MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: AppTheme.glassBorder, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2)),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Row(children: [
            if (onBack != null)
              Expanded(
                  child: OutlinedButton(
                      onPressed: onBack,
                      child: const Text('Назад'))),
            if (onBack != null) const SizedBox(width: 14),
            Expanded(
              flex: onBack != null ? 2 : 1,
              child: GradientButton(
                text:
                    currentStep == 2 ? 'Создать сказку' : 'Далее',
                icon: currentStep == 2 ? Icons.auto_stories : null,
                onPressed:
                    canProceed ? (onSubmit ?? onNext) : null,
                isLoading: isSubmitting,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────

Widget _charAvatar(dynamic c) {
  final url = c.avatarUrl;
  final initial =
      (c.name as String).isNotEmpty ? c.name[0].toUpperCase() : '?';
  return Container(
    width: 52,
    height: 52,
    decoration: const BoxDecoration(
        shape: BoxShape.circle, gradient: AppTheme.primaryGradient),
    clipBehavior: Clip.antiAlias,
    child: url != null
        ? CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Center(
                child: Text(initial,
                    style: AppTheme.body(
                        size: 20,
                        weight: FontWeight.w700,
                        color: Colors.white))),
          )
        : Center(
            child: Text(initial,
                style: AppTheme.body(
                    size: 20,
                    weight: FontWeight.w700,
                    color: Colors.white))),
  );
}

Widget _badge(String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: AppTheme.body(
              size: 11,
              weight: FontWeight.w600,
              color: AppTheme.primaryColor)),
    );

String _ageSuffix(int age) {
  final m10 = age % 10, m100 = age % 100;
  if (m100 >= 11 && m100 <= 19) return 'лет';
  if (m10 == 1) return 'год';
  if (m10 >= 2 && m10 <= 4) return 'года';
  return 'лет';
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(children: [
          Text(message,
              style:
                  AppTheme.body(size: 14, color: AppTheme.errorColor)),
          const SizedBox(height: 8),
          TextButton(
              onPressed: onRetry, child: const Text('Повторить')),
        ]),
      );
}

class _ShimmerRow extends StatelessWidget {
  const _ShimmerRow();
  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(
            3,
            (_) => const Expanded(
                child: Padding(
                    padding: EdgeInsets.only(right: 10),
                    child:
                        ShimmerBox(height: 100, borderRadius: 14)))),
      );
}
