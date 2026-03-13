import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/character.dart';
import '../../providers/character_provider.dart';
import '../../widgets/photo_picker.dart';

/// Bottom-sheet dialog for creating or editing a character.
///
/// When [existingCharacter] is `null` the dialog operates in **create** mode;
/// otherwise it pre-fills all fields for editing.
class CharacterCreateDialog extends ConsumerStatefulWidget {
  /// Pass an existing character to open the dialog in edit mode.
  final CharacterModel? existingCharacter;

  /// Called after a successful save (create or update).
  final VoidCallback onSaved;

  const CharacterCreateDialog({
    super.key,
    this.existingCharacter,
    required this.onSaved,
  });

  /// Convenience helper to show the dialog as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    CharacterModel? character,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CharacterCreateDialog(
        existingCharacter: character,
        onSaved: onSaved,
      ),
    );
  }

  @override
  ConsumerState<CharacterCreateDialog> createState() =>
      _CharacterCreateDialogState();
}

class _CharacterCreateDialogState
    extends ConsumerState<CharacterCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  String _selectedType = 'child';
  String _selectedGender = 'male';
  bool _isSaving = false;

  /// Photos that have been picked locally but not yet uploaded.
  final List<_PendingPhoto> _pendingPhotos = [];

  bool get _isEditing => widget.existingCharacter != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existingCharacter;
    if (c != null) {
      _nameController.text = c.name;
      _ageController.text = c.age?.toString() ?? '';
      _selectedType = c.characterType;
      _selectedGender = c.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Gender options depend on character type
  // ---------------------------------------------------------------------------

  List<_GenderOption> get _genderOptions {
    if (_selectedType == 'child') {
      return [
        _GenderOption(value: 'male', label: 'Мальчик', icon: Icons.boy),
        _GenderOption(value: 'female', label: 'Девочка', icon: Icons.girl),
      ];
    }
    return [
      _GenderOption(value: 'male', label: 'Мужской', icon: Icons.male),
      _GenderOption(value: 'female', label: 'Женский', icon: Icons.female),
    ];
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(charactersProvider.notifier);
      final name = _nameController.text.trim();
      final age =
          _ageController.text.trim().isNotEmpty
              ? int.tryParse(_ageController.text.trim())
              : null;

      if (_isEditing) {
        final id = widget.existingCharacter!.id;
        await notifier.updateCharacter(
          id,
          name: name,
          characterType: _selectedType,
          gender: _selectedGender,
          age: age,
        );

        // Upload pending photos
        for (final pending in _pendingPhotos) {
          await notifier.addPhoto(id, pending.bytes, pending.filename);
        }
      } else {
        final created = await notifier.createCharacter(
          name: name,
          characterType: _selectedType,
          gender: _selectedGender,
          age: age,
        );

        // Upload pending photos
        for (final pending in _pendingPhotos) {
          await notifier.addPhoto(created.id, pending.bytes, pending.filename);
        }
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingLg,
          AppTheme.spacingMd,
          AppTheme.spacingLg,
          AppTheme.spacingLg,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppTheme.textLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                _isEditing ? 'Редактировать персонажа' : 'Новый персонаж',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // 1. Character type
              Text('Тип персонажа',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppTheme.spacingSm),
              _TypeSelector(
                selected: _selectedType,
                onChanged: (type) {
                  setState(() {
                    _selectedType = type;
                    // Reset gender when type changes to keep labels consistent.
                    _selectedGender = 'male';
                  });
                },
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // 2. Gender
              Text('Пол', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppTheme.spacingSm),
              _GenderSelector(
                options: _genderOptions,
                selected: _selectedGender,
                onChanged: (g) => setState(() => _selectedGender = g),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // 3. Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  hintText: 'Введите имя персонажа',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Пожалуйста, введите имя';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // 4. Age
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Возраст',
                  hintText: 'Введите возраст',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty) {
                    final age = int.tryParse(v.trim());
                    if (age == null || age < 0 || age > 150) {
                      return 'Введите корректный возраст';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // 5. Photos
              PhotoPicker(
                existingPhotos: widget.existingCharacter?.photos ?? [],
                maxPhotos: 3,
                onPhotoAdded: (bytes, filename) {
                  setState(() {
                    _pendingPhotos.add(
                        _PendingPhoto(bytes: bytes, filename: filename));
                  });
                },
                onPhotoRemoved: (photoId) async {
                  if (_isEditing) {
                    final notifier = ref.read(charactersProvider.notifier);
                    await notifier.deletePhoto(
                        widget.existingCharacter!.id, photoId);
                  }
                },
              ),

              // Show pending (not yet uploaded) photos as small info chips
              if (_pendingPhotos.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingSm),
                Wrap(
                  spacing: AppTheme.spacingSm,
                  children: _pendingPhotos.asMap().entries.map((entry) {
                    return Chip(
                      avatar: const Icon(Icons.image, size: 18),
                      label: Text(
                        entry.value.filename,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onDeleted: () {
                        setState(() => _pendingPhotos.removeAt(entry.key));
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: AppTheme.spacingXl),

              // 6. Save button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEditing ? 'Сохранить' : 'Создать'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Private helper widgets
// =============================================================================

class _TypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  static const _types = [
    _TypeOption(value: 'child', label: 'Ребёнок', icon: Icons.child_care),
    _TypeOption(value: 'adult', label: 'Взрослый', icon: Icons.person),
    _TypeOption(value: 'pet', label: 'Питомец', icon: Icons.pets),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _types.map((t) {
        final isSelected = t.value == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: t.value != _types.last.value ? AppTheme.spacingSm : 0,
            ),
            child: ChoiceChip(
              label: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(t.icon,
                      size: 18,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(t.label),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => onChanged(t.value),
              showCheckmark: false,
              selectedColor: AppTheme.primaryLight.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: AppTheme.spacingSm,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  final List<_GenderOption> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _GenderSelector({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((o) {
        final isSelected = o.value == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: o.value != options.last.value ? AppTheme.spacingSm : 0,
            ),
            child: ChoiceChip(
              label: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(o.icon,
                      size: 18,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(o.label),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => onChanged(o.value),
              showCheckmark: false,
              selectedColor: AppTheme.primaryLight.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: AppTheme.spacingSm,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Value classes
// ---------------------------------------------------------------------------

class _TypeOption {
  final String value;
  final String label;
  final IconData icon;
  const _TypeOption(
      {required this.value, required this.label, required this.icon});
}

class _GenderOption {
  final String value;
  final String label;
  final IconData icon;
  _GenderOption(
      {required this.value, required this.label, required this.icon});
}

class _PendingPhoto {
  final Uint8List bytes;
  final String filename;
  const _PendingPhoto({required this.bytes, required this.filename});
}
