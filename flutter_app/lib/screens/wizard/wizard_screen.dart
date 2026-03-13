import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../models/catalog.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/character_provider.dart';
import '../../providers/generation_provider.dart';
import '../../widgets/character_card.dart';
import 'character_create_dialog.dart';

/// 3-step wizard for creating a new story.
///
/// Step 1: Select characters (existing + create new)
/// Step 2: Choose age range, education, genre, world, base tale (optional)
/// Step 3: Configure page count and reading duration
class WizardScreen extends ConsumerStatefulWidget {
  const WizardScreen({super.key});

  @override
  ConsumerState<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends ConsumerState<WizardScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1: Characters
  final Set<String> _selectedCharacterIds = {};

  // Step 2: Settings
  String _ageRange = '3-5';
  double _educationLevel = 0.5;
  int? _selectedGenreId;
  int? _selectedWorldId;
  int? _selectedBaseTaleId;

  // Step 3: Format
  int _pageCount = 10;
  int _readingDuration = 10;

  bool get _canProceedStep1 => _selectedCharacterIds.isNotEmpty;

  bool get _canProceedStep2 =>
      _selectedGenreId != null && _selectedWorldId != null;

  bool get _canSubmit => _canProceedStep1 && _canProceedStep2;

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
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
          AppRoutes.generationProgress.replaceAll(':jobId', job.id),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать сказку'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: Column(
        children: [
          // Step indicator
          _StepIndicator(
            currentStep: _currentStep,
            labels: const ['Персонажи', 'Настройки', 'Формат'],
          ),

          // Step content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentStep(),
            ),
          ),

          // Navigation buttons
          _BottomNavigation(
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
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _Step1Characters(
          key: const ValueKey('step1'),
          selectedIds: _selectedCharacterIds,
          onSelectionChanged: (ids) {
            setState(() {
              _selectedCharacterIds.clear();
              _selectedCharacterIds.addAll(ids);
            });
          },
        );
      case 1:
        return _Step2Settings(
          key: const ValueKey('step2'),
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
          onBaseTaleChanged: (v) => setState(() => _selectedBaseTaleId = v),
        );
      case 2:
        return _Step3Format(
          key: const ValueKey('step3'),
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
}

// =============================================================================
// Step Indicator
// =============================================================================

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> labels;

  const _StepIndicator({required this.currentStep, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      child: Row(
        children: List.generate(labels.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted
                    ? AppTheme.primaryColor
                    : AppTheme.textLight.withValues(alpha: 0.3),
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isActive = stepIndex == currentStep;
          final isCompleted = stepIndex < currentStep;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppTheme.primaryColor
                      : isCompleted
                          ? AppTheme.successColor
                          : AppTheme.textLight.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.white : AppTheme.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[stepIndex],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// =============================================================================
// Step 1: Characters
// =============================================================================

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
    final charactersAsync = ref.watch(charactersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выберите персонажей',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Выберите одного или нескольких персонажей для вашей сказки',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Create new character button
          OutlinedButton.icon(
            onPressed: () {
              CharacterCreateDialog.show(
                context,
                onSaved: () => ref.invalidate(charactersProvider),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Создать персонажа'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Characters list
          charactersAsync.when(
            data: (characters) {
              if (characters.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingXl),
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppTheme.textLight.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          'У вас пока нет персонажей',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(
                          'Создайте хотя бы одного персонажа',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textLight,
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: characters.map((character) {
                  final isSelected = selectedIds.contains(character.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                    child: CharacterCard(
                      character: character,
                      isSelected: isSelected,
                      onTap: () {
                        final newIds = Set<String>.from(selectedIds);
                        if (isSelected) {
                          newIds.remove(character.id);
                        } else {
                          newIds.add(character.id);
                        }
                        onSelectionChanged(newIds);
                      },
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingXl),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppTheme.errorColor),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text('Ошибка загрузки: $e'),
                    TextButton(
                      onPressed: () => ref.invalidate(charactersProvider),
                      child: const Text('Повторить'),
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
// Step 2: Settings
// =============================================================================

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Age Range
          Text('Возрастная группа',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          _AgeRangeSelector(
            selected: ageRange,
            onChanged: onAgeRangeChanged,
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Education Level
          Text('Уровень образовательности',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          _EducationSlider(
            value: educationLevel,
            onChanged: onEducationLevelChanged,
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Genre
          Text('Жанр *', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          genresAsync.when(
            data: (genres) => _CatalogGrid<Genre>(
              items: genres,
              selectedId: selectedGenreId,
              onSelected: onGenreChanged,
              labelOf: (g) => g.nameRu,
              idOf: (g) => g.id,
            ),
            loading: () => const _LoadingShimmer(),
            error: (e, _) => _ErrorRetry(
              message: 'Ошибка загрузки жанров',
              onRetry: () => ref.invalidate(genresProvider),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // World
          Text('Мир *', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          worldsAsync.when(
            data: (worlds) => _CatalogGrid<World>(
              items: worlds,
              selectedId: selectedWorldId,
              onSelected: onWorldChanged,
              labelOf: (w) => w.nameRu,
              idOf: (w) => w.id,
            ),
            loading: () => const _LoadingShimmer(),
            error: (e, _) => _ErrorRetry(
              message: 'Ошибка загрузки миров',
              onRetry: () => ref.invalidate(worldsProvider),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Base Tale (optional)
          Row(
            children: [
              Text('Сказка-основа',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: AppTheme.spacingSm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.textLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  'необязательно',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          baseTalesAsync.when(
            data: (tales) => _BaseTaleSelector(
              tales: tales,
              selectedId: selectedBaseTaleId,
              onSelected: onBaseTaleChanged,
            ),
            loading: () => const _LoadingShimmer(),
            error: (e, _) => _ErrorRetry(
              message: 'Ошибка загрузки сказок',
              onRetry: () => ref.invalidate(baseTalesProvider),
            ),
          ),

          // Extra padding at the bottom for scroll
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }
}

// =============================================================================
// Step 3: Format
// =============================================================================

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
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Формат сказки',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Настройте длину и время чтения',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // Page count
          Text('Количество страниц',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: pageCount.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 25,
                  label: '$pageCount',
                  onChanged: (v) => onPageCountChanged(v.round()),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '$pageCount стр.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          _PageCountPresets(
            selected: pageCount,
            onSelected: onPageCountChanged,
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // Reading duration
          Text('Время чтения',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: readingDuration.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 25,
                  label: '$readingDuration мин',
                  onChanged: (v) => onReadingDurationChanged(v.round()),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  '$readingDuration мин.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          _DurationPresets(
            selected: readingDuration,
            onSelected: onReadingDurationChanged,
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // Summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppTheme.infoColor, size: 20),
                      const SizedBox(width: AppTheme.spacingSm),
                      Text(
                        'Параметры сказки',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  _InfoRow(label: 'Страниц', value: '$pageCount'),
                  _InfoRow(
                      label: 'Время чтения', value: '$readingDuration мин'),
                  _InfoRow(
                    label: 'Иллюстраций',
                    value: '$pageCount',
                  ),
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
// Sub-widgets
// =============================================================================

class _AgeRangeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _AgeRangeSelector({required this.selected, required this.onChanged});

  static const _ranges = [
    _AgeOption(value: '3-5', label: '3-5 лет', icon: Icons.child_friendly),
    _AgeOption(value: '6-8', label: '6-8 лет', icon: Icons.child_care),
    _AgeOption(value: '9-12', label: '9-12 лет', icon: Icons.school),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _ranges.map((r) {
        final isSelected = r.value == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: r.value != _ranges.last.value ? AppTheme.spacingSm : 0,
            ),
            child: ChoiceChip(
              label: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(r.icon,
                      size: 16,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(r.label, style: const TextStyle(fontSize: 13)),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => onChanged(r.value),
              showCheckmark: false,
              selectedColor: AppTheme.primaryLight.withValues(alpha: 0.3),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EducationSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _EducationSlider({required this.value, required this.onChanged});

  String get _label {
    if (value < 0.3) return 'Минимум фактов';
    if (value < 0.7) return 'Сбалансировано';
    return 'Максимум обучения';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          value: value,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          label: _label,
          onChanged: onChanged,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Развлечение',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      )),
              Text(
                _label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text('Обучение',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      )),
            ],
          ),
        ),
      ],
    );
  }
}

class _CatalogGrid<T> extends StatelessWidget {
  final List<T> items;
  final int? selectedId;
  final ValueChanged<int?> onSelected;
  final String Function(T) labelOf;
  final int Function(T) idOf;

  const _CatalogGrid({
    required this.items,
    required this.selectedId,
    required this.onSelected,
    required this.labelOf,
    required this.idOf,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.spacingSm,
      runSpacing: AppTheme.spacingSm,
      children: items.map((item) {
        final id = idOf(item);
        final isSelected = id == selectedId;
        return ChoiceChip(
          label: Text(labelOf(item)),
          selected: isSelected,
          onSelected: (_) => onSelected(isSelected ? null : id),
          showCheckmark: false,
          selectedColor: AppTheme.primaryLight.withValues(alpha: 0.3),
        );
      }).toList(),
    );
  }
}

class _BaseTaleSelector extends StatelessWidget {
  final List<BaseTale> tales;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  const _BaseTaleSelector({
    required this.tales,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "No base tale" option
        ChoiceChip(
          label: const Text('Оригинальный сюжет'),
          avatar: const Icon(Icons.auto_awesome, size: 18),
          selected: selectedId == null,
          onSelected: (_) => onSelected(null),
          showCheckmark: false,
          selectedColor: AppTheme.accentLight.withValues(alpha: 0.3),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Wrap(
          spacing: AppTheme.spacingSm,
          runSpacing: AppTheme.spacingSm,
          children: tales.map((tale) {
            final isSelected = tale.id == selectedId;
            return ChoiceChip(
              label: Text(tale.nameRu),
              selected: isSelected,
              onSelected: (_) => onSelected(isSelected ? null : tale.id),
              showCheckmark: false,
              selectedColor: AppTheme.primaryLight.withValues(alpha: 0.3),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PageCountPresets extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _PageCountPresets({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.spacingSm,
      children: [5, 10, 15, 20, 25, 30].map((count) {
        return ActionChip(
          label: Text('$count'),
          backgroundColor: selected == count
              ? AppTheme.primaryLight.withValues(alpha: 0.3)
              : null,
          onPressed: () => onSelected(count),
        );
      }).toList(),
    );
  }
}

class _DurationPresets extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _DurationPresets({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.spacingSm,
      children: [5, 10, 15, 20, 30].map((min) {
        return ActionChip(
          label: Text('$min мин'),
          backgroundColor: selected == min
              ? AppTheme.primaryLight.withValues(alpha: 0.3)
              : null,
          onPressed: () => onSelected(min),
        );
      }).toList(),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  )),
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
        ],
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
      child: Column(
        children: [
          Text(message, style: const TextStyle(color: AppTheme.errorColor)),
          TextButton(
            onPressed: onRetry,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  final int currentStep;
  final bool canProceed;
  final bool isSubmitting;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;

  const _BottomNavigation({
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
        left: AppTheme.spacingLg,
        right: AppTheme.spacingLg,
        top: AppTheme.spacingMd,
        bottom: MediaQuery.of(context).padding.bottom + AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onBack != null)
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                child: const Text('Назад'),
              ),
            ),
          if (onBack != null) const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            flex: onBack != null ? 2 : 1,
            child: ElevatedButton(
              onPressed: canProceed
                  ? (onSubmit ?? onNext)
                  : null,
              child: isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      currentStep == 2 ? 'Создать сказку' : 'Далее',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Value classes
class _AgeOption {
  final String value;
  final String label;
  final IconData icon;
  const _AgeOption(
      {required this.value, required this.label, required this.icon});
}
