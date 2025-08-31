import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A glass container widget with a frosted appearance
class GlassContainer extends StatelessWidget {
  final Widget child;
  final bool useBlur;
  final BorderRadius? borderRadius;
  final EdgeInsets padding;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final BoxBorder? border;

  // Note: Blur sigma should come from theme extension for proper theme adaptation

  const GlassContainer({
    required this.child,
    this.useBlur = false,
    this.borderRadius,
    this.padding = EdgeInsets.zero,
    this.width,
    this.height,
    this.backgroundColor,
    this.gradientColors,
    this.border,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderR = borderRadius ?? BorderRadius.circular(24);

    // Use fake glass effect for reliable performance
    return _buildFakeGlassContainer(borderR);
  }

  Widget _buildFakeGlassContainer(BorderRadius borderR) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderR,
        // Fake glass effect using static colors
        color: backgroundColor ?? AppTheme.glassCardColor,
        // White border for glass edge effect
        border: border ?? Border.all(
          color: const Color(0x4DFFFFFF), // White with 30% opacity
          width: 1.0,
        ),
        // Remove blur shadows to eliminate edge blur effect
      ),
      child: gradientColors != null ? Container(
        decoration: BoxDecoration(
          borderRadius: borderR,
          gradient: LinearGradient(
            colors: gradientColors!,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: child,
      ) : child,
    );
  }
}
