import 'package:flutter/material.dart';
import 'dart:ui';
import '../../theme/app_theme.dart';
import '../../constants/ui_constants.dart';

/// Visual hierarchy levels for glass cards
enum GlassCardPriority { standard, prominent, alert }

/// GlassCard creates a frosted glass effect with modern design principles
/// Optimized for performance while maintaining visual hierarchy
class GlassCard extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsets contentPadding;
  final GlassCardPriority priority; // Visual hierarchy level
  final bool enablePressEffect; // Subtle press animation
  final bool useBlur; // Enable backdrop blur effect

  const GlassCard({
    required this.child,
    this.borderRadius,
    this.contentPadding = const EdgeInsets.all(UIConstants.spacingLarge), // Reduced from spacingXLarge
    this.priority = GlassCardPriority.standard,
    this.enablePressEffect = false,
    this.useBlur = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderR = borderRadius ?? BorderRadius.circular(UIConstants.borderRadiusStandard);
    
    Widget cardWidget;
    if (useBlur) {
      cardWidget = _buildBlurredGlassCard(context, borderR);
    } else {
      cardWidget = _buildFakeGlassCard(context, borderR);
    }
    
    // Add press effect if enabled
    if (enablePressEffect) {
      cardWidget = _buildPressEffectWrapper(cardWidget);
    }
    
    return cardWidget;
  }
  
  Widget _buildFakeGlassCard(BuildContext context, BorderRadius borderR) {
    // Get the glass theme extension for proper colors
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderR,
        color: glassTheme?.backgroundColor ?? AppTheme.glassCardColor, // Use theme extension if available
        border: Border.all(
          color: glassTheme?.borderColor ?? const Color(0x4DFFFFFF), // Use theme extension if available
          width: 1.0,
        ),
        // Remove blur shadows to eliminate edge blur effect
      ),
      padding: contentPadding,
      child: child,
    );
  }

  Widget _buildBlurredGlassCard(BuildContext context, BorderRadius borderR) {
    // Get the glass theme extension for proper colors
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();
    
    // Real backdrop blur effect for modal dialogs
    return ClipRRect(
      borderRadius: borderR,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderR,
            color: glassTheme?.backgroundColor ?? AppTheme.glassCardColor, // Use theme extension if available
            border: Border.all(
              color: glassTheme?.borderColor ?? const Color(0x4DFFFFFF), // Use theme extension if available
              width: 1.0,
            ),
          ),
          padding: contentPadding,
          child: child,
        ),
      ),
    );
  }
  
  Widget _buildPressEffectWrapper(Widget child) {
    return AnimatedScale(
      scale: 1.0,
      duration: UIConstants.animationFast,
      child: child,
    );
  }

  

}

/// Shows a glassmorphic snackbar at the bottom of the screen using OverlayEntry.
void showGlassCardSnackbar(BuildContext context, String message) {
  final overlay = Overlay.of(context);

  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      left: UIConstants.spacingXXXLarge,
      right: UIConstants.spacingXXXLarge,
      bottom: UIConstants.spacingXXXLarge * 2,
      child: Material(
        color: Colors.transparent,
        child: GlassCard(
          priority: GlassCardPriority.standard,
          contentPadding: const EdgeInsets.symmetric(horizontal: UIConstants.spacingXXXLarge, vertical: UIConstants.spacingXLarge),
          child: Center(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
  Future.delayed(UIConstants.delayLong, () {
    overlayEntry.remove();
  });
}
