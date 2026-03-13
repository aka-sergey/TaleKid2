import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/character.dart';

/// A compact card for displaying a character in a list or grid.
class CharacterCard extends StatelessWidget {
  final CharacterModel character;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isSelected;

  const CharacterCard({
    super.key,
    required this.character,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              // Avatar
              _Avatar(character: character, isSelected: isSelected),
              const SizedBox(width: AppTheme.spacingMd),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      character.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Row(
                      children: [
                        _TypeBadge(label: character.characterTypeLabel),
                        if (character.age != null) ...[
                          const SizedBox(width: AppTheme.spacingSm),
                          Text(
                            '${character.age} ${_ageSuffix(character.age!)}',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              if (onEdit != null || onDelete != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        color: AppTheme.textSecondary,
                        onPressed: onEdit,
                        tooltip: 'Редактировать',
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: AppTheme.errorColor,
                        onPressed: onDelete,
                        tooltip: 'Удалить',
                      ),
                  ],
                ),

              // Selection checkmark
              if (isSelected && onEdit == null && onDelete == null)
                const Icon(Icons.check_circle,
                    color: AppTheme.primaryColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns the Russian age suffix for the given number.
  static String _ageSuffix(int age) {
    final mod10 = age % 10;
    final mod100 = age % 100;
    if (mod100 >= 11 && mod100 <= 19) return 'лет';
    if (mod10 == 1) return 'год';
    if (mod10 >= 2 && mod10 <= 4) return 'года';
    return 'лет';
  }
}

/// Circular avatar showing the character's first photo or a fallback icon.
class _Avatar extends StatelessWidget {
  final CharacterModel character;
  final bool isSelected;

  const _Avatar({required this.character, required this.isSelected});

  IconData get _fallbackIcon {
    switch (character.characterType) {
      case 'child':
        return Icons.child_care;
      case 'adult':
        return Icons.person_outline;
      case 'pet':
        return Icons.pets;
      default:
        return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = character.avatarUrl;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryLight.withValues(alpha: 0.15),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryColor
              : AppTheme.primaryLight.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null
          ? CachedNetworkImage(
              imageUrl: avatarUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (_, __, ___) =>
                  Icon(_fallbackIcon, color: AppTheme.primaryColor, size: 28),
            )
          : Icon(_fallbackIcon, color: AppTheme.primaryColor, size: 28),
    );
  }
}

/// Small colored badge indicating the character type.
class _TypeBadge extends StatelessWidget {
  final String label;

  const _TypeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}
