import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Dialog for naming/renaming a story after generation completes.
/// Pre-fills with the AI-suggested title and lets the user edit.
class TitleDialog extends StatefulWidget {
  final String? suggestedTitle;
  final String storyId;

  const TitleDialog({
    super.key,
    this.suggestedTitle,
    required this.storyId,
  });

  /// Show the dialog and return the chosen title (or null if skipped).
  static Future<String?> show(
    BuildContext context, {
    String? suggestedTitle,
    required String storyId,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TitleDialog(
        suggestedTitle: suggestedTitle,
        storyId: storyId,
      ),
    );
  }

  @override
  State<TitleDialog> createState() => _TitleDialogState();
}

class _TitleDialogState extends State<TitleDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.suggestedTitle ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_note,
              color: AppTheme.accentColor,
              size: 36,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          const Text(
            'Назовите сказку',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Мы придумали название, но вы можете его изменить',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 100,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Название сказки',
              counterText: '',
            ),
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(
            'Пропустить',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  void _save() {
    final title = _controller.text.trim();
    if (title.isNotEmpty) {
      Navigator.pop(context, title);
    }
  }
}
