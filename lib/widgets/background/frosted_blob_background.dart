import 'package:flutter/material.dart';
import 'dart:ui';
import 'blob_painter.dart';
import '../../models/theme_config.dart';

/// Beautiful frosted background with animated color blobs
/// Inspired by modern glass design with dynamic primary/accent colors
class FrostedBlobBackground extends StatefulWidget {
  final Widget child;
  final ThemeConfig themeConfig;
  final bool enableAnimation;

  const FrostedBlobBackground({
    super.key,
    required this.child,
    required this.themeConfig,
    this.enableAnimation = true,
  });

  @override
  State<FrostedBlobBackground> createState() => _FrostedBlobBackgroundState();
}

class _FrostedBlobBackgroundState extends State<FrostedBlobBackground>
    with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late AnimationController _secondaryController;
  late Animation<double> _primaryAnimation;
  late Animation<double> _secondaryAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Primary animation for main blob movement (slower, more organic)
    _primaryController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    );
    
    // Secondary animation for subtle variations (faster)
    _secondaryController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    _primaryAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _primaryController,
      curve: Curves.easeInOut,
    ));

    _secondaryAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _secondaryController,
      curve: Curves.easeInOut,
    ));

    if (widget.enableAnimation) {
      _primaryController.repeat();
      _secondaryController.repeat();
    }
  }

  @override
  void didUpdateWidget(FrostedBlobBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle animation state changes
    if (widget.enableAnimation && !oldWidget.enableAnimation) {
      _primaryController.repeat();
      _secondaryController.repeat();
    } else if (!widget.enableAnimation && oldWidget.enableAnimation) {
      _primaryController.stop();
      _secondaryController.stop();
    }
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Beautiful dynamic gradient base using theme colors
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.themeConfig.primary.withValues(alpha: 0.15),
            widget.themeConfig.accent.withValues(alpha: 0.1),
            widget.themeConfig.primary.withValues(alpha: 0.08),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Animated blob layer
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_primaryAnimation, _secondaryAnimation]),
              builder: (context, child) {
                return CustomPaint(
                  painter: BlobPainter(
                    primaryColor: widget.themeConfig.primary,
                    accentColor: widget.themeConfig.accent,
                    animation: _primaryAnimation,
                    canvasSize: MediaQuery.of(context).size,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
          
          // Frosted glass overlay for depth
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 1.5,
                sigmaY: 1.5,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.02),
                      Colors.white.withValues(alpha: 0.01),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          
          // Content layer
          widget.child,
        ],
      ),
    );
  }
}

/// Optimized version for performance-sensitive areas
class SimpleFrostedBackground extends StatelessWidget {
  final Widget child;
  final ThemeConfig themeConfig;

  const SimpleFrostedBackground({
    super.key,
    required this.child,
    required this.themeConfig,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Base background with subtle gradient using theme colors
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF8F9FA),
            themeConfig.primary.withValues(alpha: 0.03),
            themeConfig.accent.withValues(alpha: 0.02),
            const Color(0xFFF8F9FA),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// Static version for settings screens - no animations, better performance
class StaticFrostedBackground extends StatelessWidget {
  final Widget child;
  final ThemeConfig themeConfig;

  const StaticFrostedBackground({
    super.key,
    required this.child,
    required this.themeConfig,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Beautiful static gradient base using theme colors
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeConfig.primary.withValues(alpha: 0.12),
            themeConfig.accent.withValues(alpha: 0.08),
            themeConfig.primary.withValues(alpha: 0.06),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Static blob layer (no animations)
          Positioned.fill(
            child: CustomPaint(
              painter: StaticBlobPainter(
                primaryColor: themeConfig.primary,
                accentColor: themeConfig.accent,
              ),
              size: Size.infinite,
            ),
          ),
          
          // Frosted glass overlay for depth
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 1.0,
                sigmaY: 1.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.02),
                      Colors.white.withValues(alpha: 0.01),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          
          // Content layer
          child,
        ],
      ),
    );
  }
}

/// Static blob painter - no animations, better performance
class StaticBlobPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  const StaticBlobPainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create base gradient background
    _paintBaseGradient(canvas, size);
    
    // Paint static blobs (no animation)
    _paintStaticBlobs(canvas, size);
  }

  void _paintBaseGradient(Canvas canvas, Size size) {
    final Paint gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor.withValues(alpha: 0.06),
          accentColor.withValues(alpha: 0.04),
          primaryColor.withValues(alpha: 0.03),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), gradientPaint);
  }

  void _paintStaticBlobs(Canvas canvas, Size size) {
    // Define static blob configurations (no animation values)
    final List<BlobConfig> blobs = [
      BlobConfig(
        color: primaryColor,
        size: size.width * 0.4,
        centerX: size.width * 0.2,
        centerY: size.height * 0.3,
        opacity: 0.15,
        blurRadius: 60.0,
      ),
      BlobConfig(
        color: primaryColor,
        size: size.width * 0.35,
        centerX: size.width * 0.8,
        centerY: size.height * 0.7,
        opacity: 0.12,
        blurRadius: 50.0,
      ),
      BlobConfig(
        color: accentColor,
        size: size.width * 0.25,
        centerX: size.width * 0.6,
        centerY: size.height * 0.2,
        opacity: 0.12,
        blurRadius: 40.0,
      ),
      BlobConfig(
        color: accentColor,
        size: size.width * 0.28,
        centerX: size.width * 0.1,
        centerY: size.height * 0.8,
        opacity: 0.10,
        blurRadius: 45.0,
      ),
    ];

    // Paint each blob
    for (final BlobConfig blob in blobs) {
      _paintBlob(canvas, blob);
    }
  }

  void _paintBlob(Canvas canvas, BlobConfig config) {
    final Paint blobPaint = Paint()
      ..color = config.color.withValues(alpha: config.opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.blurRadius);

    // Create simple circular blob for better performance
    canvas.drawCircle(
      Offset(config.centerX, config.centerY),
      config.size / 2,
      blobPaint,
    );
  }

  @override
  bool shouldRepaint(StaticBlobPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
           oldDelegate.accentColor != accentColor;
  }
}

/// Performance monitor for blob animations
class BlobPerformanceMonitor {
  static bool _isPerformanceMode = false;
  static int _frameDropCount = 0;
  static DateTime _lastCheck = DateTime.now();

  static bool get isPerformanceMode => _isPerformanceMode;

  static void checkPerformance() {
    final DateTime now = DateTime.now();
    final Duration timeSinceLastCheck = now.difference(_lastCheck);
    
    // Check every 5 seconds
    if (timeSinceLastCheck.inSeconds >= 5) {
      // If we've had more than 3 frame drops in 5 seconds, enable performance mode
      if (_frameDropCount > 3) {
        _isPerformanceMode = true;
      } else if (_frameDropCount == 0) {
        _isPerformanceMode = false;
      }
      
      _frameDropCount = 0;
      _lastCheck = now;
    }
  }

  static void reportFrameDrop() {
    _frameDropCount++;
  }

  static void reset() {
    _isPerformanceMode = false;
    _frameDropCount = 0;
    _lastCheck = DateTime.now();
  }
}
