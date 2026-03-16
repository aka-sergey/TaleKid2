import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Glass-morphism card used throughout the app — dark theme style.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius = 20,
    this.onTap,
    this.highlighted = false,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool highlighted;
  final Color? color;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    final shadow =
        _hovering ? AppTheme.cardShadowHover : AppTheme.cardShadow;
    final cardBgColor = widget.color ?? AppTheme.glassLight;

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: radius,
        border: widget.highlighted
            ? null
            : Border.all(color: AppTheme.glassBorder, width: 0.5),
        boxShadow: shadow,
      ),
      child: widget.onTap != null
          ? Material(
              color: Colors.transparent,
              borderRadius: radius,
              child: InkWell(
                borderRadius: radius,
                onTap: widget.onTap,
                child: Padding(
                  padding: widget.padding,
                  child: widget.child,
                ),
              ),
            )
          : Padding(
              padding: widget.padding,
              child: widget.child,
            ),
    );

    // Gradient border wrapper for highlighted state
    if (widget.highlighted) {
      card = Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(widget.borderRadius + 2),
          boxShadow: [
            ...shadow,
            ...AppTheme.primaryGlow,
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: radius,
          ),
          child: widget.onTap != null
              ? Material(
                  color: Colors.transparent,
                  borderRadius: radius,
                  child: InkWell(
                    borderRadius: radius,
                    onTap: widget.onTap,
                    child: Padding(
                      padding: widget.padding,
                      child: widget.child,
                    ),
                  ),
                )
              : Padding(
                  padding: widget.padding,
                  child: widget.child,
                ),
        ),
      );
    }

    if (widget.onTap != null) {
      card = MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: card,
      );
    }

    return card;
  }
}
