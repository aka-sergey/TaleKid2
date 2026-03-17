import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../models/character.dart';
import '../../providers/character_provider.dart';
import '../../widgets/gradient_button.dart';
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
        _GenderOption(value: 'male', label: 'Мальчик', emoji: '👦🏼'),
        _GenderOption(value: 'female', label: 'Девочка', emoji: '👧🏼'),
      ];
    }
    return [
      _GenderOption(value: 'male', label: 'Мужской', emoji: '👨🏼'),
      _GenderOption(value: 'female', label: 'Женский', emoji: '👩🏼'),
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
    final maxH = MediaQuery.of(context).size.height * 0.88;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                _isEditing ? 'Редактировать персонажа' : 'Новый персонаж',
                style: AppTheme.heading(size: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 1. Character type — emoji cards
              Text(
                'Тип персонажа',
                style: AppTheme.body(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              _TypeSelector(
                selected: _selectedType,
                onChanged: (type) {
                  setState(() {
                    _selectedType = type;
                    _selectedGender = 'male';
                  });
                },
              ),
              const SizedBox(height: 20),

              // 2. Gender — emoji cards
              Text(
                'Пол',
                style: AppTheme.body(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              _GenderSelector(
                options: _genderOptions,
                selected: _selectedGender,
                onChanged: (g) => setState(() => _selectedGender = g),
              ),
              const SizedBox(height: 20),

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
              const SizedBox(height: 14),

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
              const SizedBox(height: 20),

              // 5. Photos
              PhotoPicker(
                existingPhotos: widget.existingCharacter?.photos ?? [],
                maxPhotos: 3,
                pendingCount: _pendingPhotos.length,
                onPhotoAdded: (bytes, filename) {
                  final existing =
                      widget.existingCharacter?.photos.length ?? 0;
                  if (existing + _pendingPhotos.length >= 3) return;
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

              // Pending photos — show as image thumbnails (not file chips)
              if (_pendingPhotos.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _pendingPhotos.asMap().entries.map((entry) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            entry.value.bytes,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () => setState(
                                () => _pendingPhotos.removeAt(entry.key)),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: AppTheme.errorColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 13, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 28),

              // 6. Save button — gradient
              GradientButton(
                text: _isEditing ? 'Сохранить' : 'Создать персонажа',
                icon: _isEditing ? Icons.check : Icons.add,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    ),   // Container
    );   // ConstrainedBox
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
    _TypeOption(value: 'child', label: 'Ребёнок', emoji: '👶🏼'),
    _TypeOption(value: 'adult', label: 'Взрослый', emoji: '🧑🏼'),
    _TypeOption(value: 'pet', label: 'Питомец', emoji: '🐱'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _types.map((t) {
        final isSelected = t.value == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: t.value != _types.last.value ? 10 : 0,
            ),
            child: GestureDetector(
              onTap: () => onChanged(t.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.08)
                      : AppTheme.fillColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(
                      t.label,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
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
              right: o.value != options.last.value ? 10 : 0,
            ),
            child: GestureDetector(
              onTap: () => onChanged(o.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.08)
                      : AppTheme.fillColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(o.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(
                      o.label,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
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
  final String emoji;
  const _TypeOption(
      {required this.value, required this.label, required this.emoji});
}

class _GenderOption {
  final String value;
  final String label;
  final String emoji;
  _GenderOption(
      {required this.value, required this.label, required this.emoji});
}

class _PendingPhoto {
  final Uint8List bytes;
  final String filename;
  const _PendingPhoto({required this.bytes, required this.filename});
}
