import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/story.dart';

/// Lightbulb popup showing educational content (fact or question)
/// on a story page.
class EducationalPopup extends StatefulWidget {
  final EducationalContent content;

  const EducationalPopup({super.key, required this.content});

  /// Show as a modal bottom sheet.
  static Future<void> show(BuildContext context, EducationalContent content) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EducationalPopup(content: content),
    );
  }

  @override
  State<EducationalPopup> createState() => _EducationalPopupState();
}

class _EducationalPopupState extends State<EducationalPopup> {
  bool _answerRevealed = false;

  @override
  Widget build(BuildContext context) {
    final content = widget.content;
    final isFact = content.isFact;

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1735),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.glassBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Icon & topic badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isFact
                      ? AppTheme.accentColor.withValues(alpha: 0.2)
                      : AppTheme.infoColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFact ? Icons.lightbulb : Icons.quiz,
                  color: isFact ? AppTheme.accentColor : AppTheme.infoColor,
                  size: 28,
                ),
              ),
              if (content.topic != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    content.topic!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Title
          Text(
            isFact ? 'А ты знал?' : 'Вопрос!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isFact ? AppTheme.accentColor : AppTheme.infoColor,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Content text
          Text(
            content.textRu,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),

          // Answer section (for questions)
          if (content.isQuestion && content.answerRu != null) ...[
            const SizedBox(height: AppTheme.spacingLg),
            if (!_answerRevealed)
              ElevatedButton.icon(
                onPressed: () => setState(() => _answerRevealed = true),
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('Показать ответ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.infoColor,
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: AppTheme.successColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.successColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        content.answerRu!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
          ],

          const SizedBox(height: AppTheme.spacingLg),

          // Close button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
          ),
        ],
      ),
    );
  }
}
