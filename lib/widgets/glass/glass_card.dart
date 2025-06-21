import 'package:flutter/material.dart';
import 'dart:ui';
import '../../theme/app_theme.dart';

/// GlassCard creates a frosted glass effect
/// Heavily optimized for performance while maintaining the glass-like appearance
class GlassCard extends StatelessWidget {
  final Widget child;
  final bool useBlur;
  final BorderRadius? borderRadius;
  final EdgeInsets contentPadding;
  final double? opacity; // Optional opacity override for custom transparency

  // Static fields for optimization to avoid object creation on every build
  static final ImageFilter _lightBlur = ImageFilter.blur(sigmaX: 8, sigmaY: 8);

  const GlassCard({
    required this.child,
    this.useBlur = false, // Default to false for better performance
    this.borderRadius,
    this.contentPadding = EdgeInsets.zero,
    this.opacity, // Allow custom opacity for specific cards
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderR = borderRadius ?? BorderRadius.circular(24);

    // For performance critical areas, use the simulated glass effect (no blur)
    if (!useBlur) {
      return _buildSimulatedGlassCard(borderR);
    }

    // Only use actual blur effect for static/important UI elements
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderR,
        child: BackdropFilter(
          filter:
              _lightBlur, // Use static filter instance to avoid object creation
          child: _buildOptimizedContainer(borderR, true),
        ),
      ),
    );
  }

  // Simulated glass effect that doesn't use BackdropFilter
  Widget _buildSimulatedGlassCard(BorderRadius borderR) {
    // Use custom opacity if provided, otherwise use default AppTheme.glassCardColor
    final Color baseColor = opacity != null 
        ? Colors.white.withValues(alpha: opacity!)
        : AppTheme.glassCardColor;
    
    // Calculate gradient colors based on opacity
    final Color gradientColor1 = opacity != null 
        ? Colors.white.withValues(alpha: (opacity! * 1.5).clamp(0.0, 1.0)) // Slightly more opaque for top
        : const Color(0x4DFFFFFF); // Default 30% opacity
    final Color gradientColor2 = opacity != null 
        ? Colors.white.withValues(alpha: (opacity! * 1.2).clamp(0.0, 1.0)) // Slightly more opaque for bottom
        : const Color(0x33FFFFFF); // Default 20% opacity

    return Container(
      padding: contentPadding,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: borderR,
        // Simulated glass effect with gradient
        gradient: LinearGradient(
          colors: [gradientColor1, gradientColor2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // Minimal shadow for depth
        boxShadow: const [
          BoxShadow(
            color: AppTheme.glassShadowColor,
            blurRadius: 4, // Reduced for better performance
            offset: Offset(0, 2), // Smaller offset
          ),
        ],
      ),
      child: child,
    );
  }

  // Original container used with blur effect for important UI elements
  Widget _buildOptimizedContainer(BorderRadius borderR, bool hasBlur) {
    return Container(
      padding: contentPadding,
      decoration: BoxDecoration(
        color: AppTheme.glassCardColor,
        borderRadius: borderR,
        // Using a single BoxShadow is more efficient
        boxShadow: hasBlur
            ? const [
                BoxShadow(
                  color: AppTheme.glassShadowColor,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ]
            : null, // No shadow when not using blur for maximum performance
      ),
      child: child,
    );
  }
}
