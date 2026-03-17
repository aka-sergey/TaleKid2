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
  // Original 6
  'adventure': UiAssets.adventure,
  'fairy-tale': UiAssets.fairy_tale,
  'educational': UiAssets.educational,
  'friendship': UiAssets.friendship,
  'funny': UiAssets.funny,
  'bedtime': UiAssets.bedtime,
  // New 25
  'detective': UiAssets.detective,
  'rescue': UiAssets.rescue,
  'riddles': UiAssets.riddles,
  'journey': UiAssets.journey,
  'fantasy': UiAssets.fantasy,
  'space-sci-fi': UiAssets.space_sci_fi,
  'animal-stories': UiAssets.animal_stories,
  'superheroes': UiAssets.superheroes,
  'light-mystery': UiAssets.light_mystery,
  'everyday-stories': UiAssets.everyday_stories,
  'school-stories': UiAssets.school_stories,
  'moral-stories': UiAssets.moral_stories,
  'survival-nature': UiAssets.survival_nature,
  'historical-adventure': UiAssets.historical_adventure,
  'creativity-imagination': UiAssets.creativity_imagination,
  'holiday-stories': UiAssets.holiday_stories,
  'science-adventure': UiAssets.science_adventure,
  'quest-treasure-hunt': UiAssets.quest_treasure_hunt,
  'sea-adventure': UiAssets.sea_adventure,
  'prehistoric-world': UiAssets.prehistoric_world,
  'robots-technology': UiAssets.robots_technology,
  'profession-stories': UiAssets.profession_stories,
  'magical-worlds': UiAssets.magical_worlds,
  'secrets-mysteries': UiAssets.secrets_mysteries,
  'self-discovery-growing-up': UiAssets.self_discovery_growing_up,
  // Aliases
  'humor': UiAssets.funny,
  'family-stories': UiAssets.bedtime,
};

const _worldAssets = <String, String>{
  // Original 6
  'enchanted-forest': UiAssets.magic_forest,
  'space': UiAssets.space,
  'underwater': UiAssets.underwater,
  'medieval-kingdom': UiAssets.medieval_kingdom,
  'modern-city': UiAssets.modern_city,
  'dinosaur-world': UiAssets.dinosaur_world,
  // New 24
  'ancient-legends': UiAssets.ancient_legends,
  'underground-world': UiAssets.underground_world,
  'sky-kingdom': UiAssets.sky_kingdom,
  'dragon-world': UiAssets.dragon_world,
  'robot-world': UiAssets.robot_world,
  'enchanted-castle': UiAssets.enchanted_castle,
  'mysterious-island': UiAssets.mysterious_island,
  'wonder-desert': UiAssets.wonder_desert,
  'north-pole': UiAssets.north_pole,
  'jungle': UiAssets.jungle,
  'candy-land': UiAssets.candy_land,
  'dream-world': UiAssets.dream_world,
  'lost-city': UiAssets.lost_city,
  'pirate-islands': UiAssets.pirate_islands,
  'magic-school': UiAssets.magic_school,
  'deep-ocean': UiAssets.deep_ocean,
  'moon-base': UiAssets.moon_base,
  'monster-planet': UiAssets.monster_planet,
  'giant-world': UiAssets.giant_world,
  'miniature-world': UiAssets.miniature_world,
  'cloud-country': UiAssets.cloud_country,
  'shadow-labyrinth': UiAssets.shadow_labyrinth,
  'time-kingdom': UiAssets.time_kingdom,
  'elemental-world': UiAssets.elemental_world,
  // Aliases
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
  String _illustrationStyle = 'watercolor'; // default
  String _userContext = ''; // personal context to weave into the story
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
        illustrationStyle: _illustrationStyle,
        userContext: _userContext.trim().isEmpty ? null : _userContext.trim(),
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
          illustrationStyle: _illustrationStyle,
          onAgeRangeChanged: (v) => setState(() => _ageRange = v),
          onEducationLevelChanged: (v) =>
              setState(() => _educationLevel = v),
          onGenreChanged: (v) => setState(() => _selectedGenreId = v),
          onWorldChanged: (v) => setState(() => _selectedWorldId = v),
          onBaseTaleChanged: (v) =>
              setState(() => _selectedBaseTaleId = v),
          onStyleChanged: (v) => setState(() => _illustrationStyle = v),
        );
      case 2:
        return _Step3Format(
          key: const ValueKey('s3'),
          pageCount: _pageCount,
          readingDuration: _readingDuration,
          userContext: _userContext,
          onPageCountChanged: (v) => setState(() => _pageCount = v),
          onReadingDurationChanged: (v) =>
              setState(() => _readingDuration = v),
          onUserContextChanged: (v) => setState(() => _userContext = v),
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
              const Text('ВЫБЕРИТЕ ПЕРСОНАЖЕЙ',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFDD00),
                    letterSpacing: 1.2,
                  )),
              const SizedBox(height: 8),
              Text(
                  'Выберите одного или нескольких персонажей для вашей сказки',
                  style: AppTheme.body(
                      size: 42, color: AppTheme.textSecondary)),
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
                                            size: 30,
                                            weight: FontWeight.w700,
                                            color: Colors.white)),
                                    const SizedBox(height: 6),
                                    Row(children: [
                                      _badge(c.characterTypeLabel),
                                      if (c.age != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                            '${c.age} ${_ageSuffix(c.age!)}',
                                            style: AppTheme.body(
                                                size: 24,
                                                color: Colors.white)),
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
  final String illustrationStyle;
  final ValueChanged<String> onAgeRangeChanged;
  final ValueChanged<double> onEducationLevelChanged;
  final ValueChanged<int?> onGenreChanged;
  final ValueChanged<int?> onWorldChanged;
  final ValueChanged<int?> onBaseTaleChanged;
  final ValueChanged<String> onStyleChanged;

  const _Step2Settings({
    super.key,
    required this.ageRange,
    required this.educationLevel,
    required this.selectedGenreId,
    required this.selectedWorldId,
    required this.selectedBaseTaleId,
    required this.illustrationStyle,
    required this.onAgeRangeChanged,
    required this.onEducationLevelChanged,
    required this.onGenreChanged,
    required this.onWorldChanged,
    required this.onBaseTaleChanged,
    required this.onStyleChanged,
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
                Text('ВОЗРАСТНАЯ ГРУППА',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFDD00),
                      letterSpacing: 1.2,
                    )),
                const SizedBox(height: 12),
                _AgeCards(
                    selected: ageRange, onChanged: onAgeRangeChanged),
                const SizedBox(height: 28),
                Text('УРОВЕНЬ ОБРАЗОВАТЕЛЬНОСТИ',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFDD00),
                      letterSpacing: 1.2,
                    )),
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
                Text('ВЫБИРАЕМ ЖАНР',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFDD00),
                      letterSpacing: 1.2,
                    )),
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
                Text('ВЫБИРАЕМ МИР',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFDD00),
                      letterSpacing: 1.2,
                    )),
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

          // ── Wide: Base tale ─────────────────────────────────────────
          SizedBox(
            width: wideMaxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('СКАЗКА-ОСНОВА',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFDD00),
                        letterSpacing: 1.2,
                      )),
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
          const SizedBox(height: 28),

          // ── Wide: Illustration Styles ────────────────────────────────
          SizedBox(
            width: wideMaxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('СТИЛЬ ИЛЛЮСТРАЦИЙ',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFDD00),
                      letterSpacing: 1.2,
                    )),
                const SizedBox(height: 12),
                _StyleSelector(
                    selected: illustrationStyle,
                    onChanged: onStyleChanged),
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

class _Step3Format extends StatefulWidget {
  final int pageCount;
  final int readingDuration;
  final String userContext;
  final ValueChanged<int> onPageCountChanged;
  final ValueChanged<int> onReadingDurationChanged;
  final ValueChanged<String> onUserContextChanged;

  const _Step3Format({
    super.key,
    required this.pageCount,
    required this.readingDuration,
    required this.userContext,
    required this.onPageCountChanged,
    required this.onReadingDurationChanged,
    required this.onUserContextChanged,
  });

  @override
  State<_Step3Format> createState() => _Step3FormatState();
}

class _Step3FormatState extends State<_Step3Format> {
  late final TextEditingController _contextCtrl;

  @override
  void initState() {
    super.initState();
    _contextCtrl = TextEditingController(text: widget.userContext);
  }

  @override
  void dispose() {
    _contextCtrl.dispose();
    super.dispose();
  }

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
                value: widget.pageCount.toDouble(),
                min: 5,
                max: 30,
                divisions: 25,
                label: '${widget.pageCount}',
                onChanged: (v) => widget.onPageCountChanged(v.round()),
              ),
              _PresetRow(
                  values: const [5, 10, 15, 20, 25, 30],
                  selected: widget.pageCount,
                  onSelected: widget.onPageCountChanged),
              const SizedBox(height: 28),
              Text('Время чтения',
                  style: AppTheme.heading(size: 17)),
              const SizedBox(height: 12),
              Slider(
                value: widget.readingDuration.toDouble(),
                min: 5,
                max: 30,
                divisions: 25,
                label: '${widget.readingDuration} мин',
                onChanged: (v) =>
                    widget.onReadingDurationChanged(v.round()),
              ),
              _PresetRow(
                  values: const [5, 10, 15, 20, 30],
                  selected: widget.readingDuration,
                  onSelected: widget.onReadingDurationChanged,
                  suffix: ' мин'),
              const SizedBox(height: 32),
              // ── Personal Context Section ──────────────────────────────
              Text('Личный контекст', style: AppTheme.heading(size: 17)),
              const SizedBox(height: 4),
              Text(
                'Поделитесь событием из жизни — ИИ вплетёт его в сказку',
                style: AppTheme.body(size: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contextCtrl,
                onChanged: widget.onUserContextChanged,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText:
                      'Например: «Сегодня мы ходили в зоопарк и видели '
                      'слонов, жирафов и тигров. Маша была в восторге '
                      'от попугаев»',
                  hintStyle: AppTheme.body(
                      size: 13, color: AppTheme.textLight),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 14, right: 8, bottom: 56),
                    child: Icon(Icons.auto_stories_rounded,
                        color: AppTheme.primaryColor, size: 22),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: AppTheme.fillColor,
                  contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                ),
                style: AppTheme.body(size: 14),
              ),
              // Параметры сказки — скрыты (visibility: hidden)
              const SizedBox.shrink(),
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
                          ? const Color(0xFFFFAA00)
                          : AppTheme.borderColor,
                      width: sel ? 3.5 : 1),
                  boxShadow: sel
                      ? [BoxShadow(
                          color: const Color(0xFFFFAA00).withValues(alpha: 0.35),
                          blurRadius: 12,
                          spreadRadius: 1,
                        )]
                      : null,
                  color: sel
                      ? const Color(0xFFFFAA00).withValues(alpha: 0.08)
                      : AppTheme.glassLight,
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

// Genres hidden from UI
const _hiddenGenreSlugs = {
  'light-mystery',
  'self-discovery-growing-up',
  'survival-nature',
  'creativity-imagination',
  'humor',
};

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
    final visible = genres.where((g) => !_hiddenGenreSlugs.contains(g.slug)).toList();
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
        children: visible.map((g) {
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
                        ? const Color(0xFFFFAA00)
                        : AppTheme.borderColor,
                    width: sel ? 3.5 : 1),
                color: sel
                    ? const Color(0xFFFFAA00).withValues(alpha: 0.08)
                    : AppTheme.glassLight,
                boxShadow: sel
                    ? [BoxShadow(
                        color: const Color(0xFFFFAA00).withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )]
                    : null,
              ),
              child: Column(children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(11)),
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

// Worlds hidden from UI
const _hiddenWorldSlugs = {
  'underwater',
  'underwater-kingdom',
  'sky-kingdom',
  'shadow-labyrinth',
  'time-kingdom',
  'elemental-world',
  'north-pole',
  'medieval-kingdom',
  'modern-city',
  'wonder-desert',
  'dream-world',
  'pirate-islands',
  // candy-land restored
};

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
    final visible = worlds.where((w) => !_hiddenWorldSlugs.contains(w.slug)).toList();
    return LayoutBuilder(builder: (ctx, box) {
      // Adaptive columns: ~160px per card, min 3, max 8
      final cols = (box.maxWidth / 160).floor().clamp(3, 8);
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: visible.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85),
        itemBuilder: (_, i) {
          final w = visible[i];
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
                        ? const Color(0xFFFFAA00)
                        : AppTheme.borderColor,
                    width: sel ? 3.5 : 1),
                boxShadow: sel
                    ? [BoxShadow(
                        color: const Color(0xFFFFAA00).withValues(alpha: 0.35),
                        blurRadius: 12,
                        spreadRadius: 1,
                      )]
                    : null,
                color: sel
                    ? const Color(0xFFFFAA00).withValues(alpha: 0.08)
                    : AppTheme.glassLight,
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

  static const _selColor = Color(0xFFFFAA00);
  static const _selBg = Color(0x14FFAA00); // 8% opacity

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Оригинальный сюжет" chip
        _TaleChip(
          label: 'Оригинальный сюжет',
          icon: Icons.auto_awesome,
          selected: selectedId == null,
          onTap: () => onSelected(null),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: tales.map((t) {
            final sel = t.id == selectedId;
            return _TaleChip(
              label: t.nameRu,
              selected: sel,
              onTap: () => onSelected(sel ? null : t.id),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TaleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  const _TaleChip(
      {required this.label,
      required this.selected,
      required this.onTap,
      this.icon});

  static const _selColor = Color(0xFFFFAA00);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? _selColor.withValues(alpha: 0.12)
              : AppTheme.glassLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _selColor : AppTheme.borderColor,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _selColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color: selected ? _selColor : AppTheme.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTheme.body(
                size: 14,
                weight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? _selColor : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Illustration Style Selector
// ═════════════════════════════════════════════════════════════════════════

class _StyleData {
  final String slug;
  final String nameRu;
  final String description;
  final String imageUrl;
  const _StyleData(this.slug, this.nameRu, this.description, this.imageUrl);
}

class _StyleSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  static const _baseUrl =
      'https://s3.twcstorage.ru/3e487a89-899c-4ef8-91e2-0900cb899801'
      '/landing-assets/styles';

  static const _styles = [
    _StyleData('watercolor', 'Акварель',
        'Мягкие цвета и нежные переходы', '$_baseUrl/watercolor.png'),
    _StyleData('3d-pixar', '3D Анимация',
        'Яркий мир как в мультфильмах Pixar', '$_baseUrl/3d-pixar.png'),
    _StyleData('disney', 'Disney',
        'Волшебство в стиле Disney', '$_baseUrl/disney.png'),
    _StyleData('comic', 'Комикс',
        'Динамичные сцены с яркими контурами', '$_baseUrl/comic.png'),
    _StyleData('anime', 'Аниме',
        'Японский стиль с большими глазами', '$_baseUrl/anime.png'),
    _StyleData('pastel', 'Пастель',
        'Нежные пастельные тона', '$_baseUrl/pastel.png'),
    _StyleData('classic-book', 'Книжная классика',
        'Тёплый стиль классических иллюстраций', '$_baseUrl/classic-book.png'),
    // pop-art hidden from UI
  ];

  const _StyleSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      final cols = (box.maxWidth / 160).floor().clamp(3, 8);
      final spacing = 10.0;
      final itemWidth = (box.maxWidth - spacing * (cols - 1)) / cols;
      final imageHeight = (itemWidth * 0.65).clamp(70.0, 130.0);

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: _styles.map((s) {
          final isSel = s.slug == selected;
          return GestureDetector(
            onTap: () => onChanged(s.slug),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: itemWidth,
              decoration: BoxDecoration(
                color: isSel
                    ? AppTheme.primaryColor.withValues(alpha: 0.08)
                    : AppTheme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSel
                      ? AppTheme.primaryColor
                      : AppTheme.borderColor,
                  width: isSel ? 2.0 : 1.0,
                ),
                boxShadow: isSel ? AppTheme.cardShadow : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cover image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(13)),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: s.imageUrl,
                          height: imageHeight,
                          width: itemWidth,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(
                                height: imageHeight,
                                color: AppTheme.fillColor,
                              ),
                          errorWidget: (_, __, ___) =>
                              Container(
                                height: imageHeight,
                                color: AppTheme.fillColor,
                                child: const Icon(Icons.image_not_supported,
                                    color: Colors.grey),
                              ),
                        ),
                        if (isSel)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Label
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.nameRu,
                          style: AppTheme.body(
                            size: 13,
                            weight: FontWeight.w700,
                            color: isSel
                                ? AppTheme.primaryColor
                                : AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
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
    width: 156,
    height: 156,
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
                        size: 60,
                        weight: FontWeight.w700,
                        color: Colors.white))),
          )
        : Center(
            child: Text(initial,
                style: AppTheme.body(
                    size: 60,
                    weight: FontWeight.w700,
                    color: Colors.white))),
  );
}

Widget _badge(String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          style: AppTheme.body(
              size: 22,
              weight: FontWeight.w600,
              color: Colors.white)),
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
