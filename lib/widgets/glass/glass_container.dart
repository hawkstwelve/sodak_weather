import 'package:flutter/material.dart';
import 'dart:ui';
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

  // Static fields for optimization to avoid object creation on every build
  static final ImageFilter _lightBlur = ImageFilter.blur(sigmaX: 8, sigmaY: 8);

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

    // For performance critical areas, use the simulated glass effect
    if (!useBlur) {
      return _buildSimulatedGlassContainer(borderR, context);
    }

    // Only use actual blur effect for static/important UI elements
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderR,
        child: BackdropFilter(
          filter: _lightBlur,
          child: _buildSimulatedGlassContainer(borderR, context),
        ),
      ),
    );
  }

  Widget _buildSimulatedGlassContainer(
    BorderRadius borderR,
    BuildContext context,
  ) {
    final Color bgColor = backgroundColor ?? AppTheme.glassCardColor;
    final List<Color> gradient =
        gradientColors ??
        [
          const Color(0xE6FFFFFF), // White with 90% opacity
          const Color(0xCCFFFFFF), // White with 80% opacity
        ];

    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderR,
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: border,
        boxShadow: const [
          BoxShadow(
            color: AppTheme.glassShadowColor,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
