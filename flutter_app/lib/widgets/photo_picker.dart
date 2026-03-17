import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/theme.dart';
import '../models/character.dart';

/// Cross-platform photo picker widget.
///
/// On Android: shows bottom-sheet with gallery / camera options via image_picker.
/// On Web: shows file picker (gallery source only, since camera is unavailable).
/// Displays existing photos as thumbnails with a delete button.
class PhotoPicker extends StatelessWidget {
  /// Already-uploaded photos to display.
  final List<CharacterPhoto> existingPhotos;

  /// Callback when a new photo is selected by the user.
  final Function(Uint8List bytes, String filename) onPhotoAdded;

  /// Callback when the user taps the delete button on an existing photo.
  final Function(String photoId) onPhotoRemoved;

  /// Maximum number of photos allowed (existing + pending).
  final int maxPhotos;

  /// Number of locally-picked photos not yet uploaded (to enforce total limit).
  final int pendingCount;

  const PhotoPicker({
    super.key,
    required this.existingPhotos,
    required this.onPhotoAdded,
    required this.onPhotoRemoved,
    this.maxPhotos = 3,
    this.pendingCount = 0,
  });

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final filename = picked.name;
    onPhotoAdded(bytes, filename);
  }

  void _showSourcePicker(BuildContext context) {
    if (kIsWeb) {
      // On web, camera is not available -- open gallery directly.
      _pickImage(context, ImageSource.gallery);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Галерея'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(context, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Камера'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(context, ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPhotos = existingPhotos.length + pendingCount;
    final canAddMore = totalPhotos < maxPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              'Фотографии',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              '$totalPhotos/$maxPhotos',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textLight,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // Photo grid
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Existing photos
              ...existingPhotos.map((photo) => _PhotoThumbnail(
                    photo: photo,
                    onDelete: () => onPhotoRemoved(photo.id),
                  )),

              // Add button
              if (canAddMore)
                _AddPhotoButton(onTap: () => _showSourcePicker(context)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Displays a single photo thumbnail with a delete badge.
class _PhotoThumbnail extends StatelessWidget {
  final CharacterPhoto photo;
  final VoidCallback onDelete;

  const _PhotoThumbnail({
    required this.photo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingSm),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: CachedNetworkImage(
              imageUrl: photo.s3Url,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 100,
                height: 100,
                color: AppTheme.backgroundColor,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 100,
                height: 100,
                color: AppTheme.backgroundColor,
                child: const Icon(Icons.broken_image_outlined,
                    color: AppTheme.textLight),
              ),
            ),
          ),
          // Delete badge
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The dashed "add photo" button shown at the end of the list.
class _AddPhotoButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPhotoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: AppTheme.primaryLight,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          color: AppTheme.primaryLight.withValues(alpha: 0.08),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                color: AppTheme.primaryColor, size: 28),
            SizedBox(height: AppTheme.spacingXs),
            Text(
              'Добавить',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
