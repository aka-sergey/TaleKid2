import 'dart:ui';

import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Frosted-glass card with backdrop blur — «Зачарованная ночь» style.
///
/// Uses [BackdropFilter] + semi-transparent fill for a glass-morphism effect.
/// Works best over dark or image backgrounds.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius = 20,
    this.blurAmount = 16,
    this.opacity = 0.10,
    this.borderOpacity = 0.08,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  /// Strength of the backdrop blur (default 16).
  final double blurAmount;

  /// Background fill opacity 0..1 over white (default 0.10).
  final double opacity;

  /// Border opacity 0..1 over white (default 0.08).
  final double borderOpacity;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final fillColor = Colors.white.withValues(alpha: opacity);
    final borderColor = Colors.white.withValues(alpha: borderOpacity);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurAmount,
            sigmaY: blurAmount,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: radius,
              border: Border.all(color: borderColor, width: 0.5),
              boxShadow: AppTheme.cardShadow,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
