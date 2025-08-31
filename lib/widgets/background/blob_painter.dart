import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painter that creates beautiful animated color blobs for the background
class BlobPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final Animation<double> animation;
  final Size canvasSize;

  const BlobPainter({
    required this.primaryColor,
    required this.accentColor,
    required this.animation,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create base gradient background
    _paintBaseGradient(canvas, size);
    
    // Paint animated blobs
    _paintAnimatedBlobs(canvas, size);
  }

  void _paintBaseGradient(Canvas canvas, Size size) {
    // Subtle gradient background using primary color
    final Paint gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor.withValues(alpha: 0.08),
          accentColor.withValues(alpha: 0.06),
          primaryColor.withValues(alpha: 0.04),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), gradientPaint);
  }

  void _paintAnimatedBlobs(Canvas canvas, Size size) {
    final double animationValue = animation.value;
    
    // Define blob configurations with different sizes and movement patterns
    final List<BlobConfig> blobs = [
      // Large primary blobs
      BlobConfig(
        color: primaryColor,
        size: size.width * 0.4,
        centerX: size.width * 0.2 + (math.sin(animationValue * 2 * math.pi + 0) * size.width * 0.1),
        centerY: size.height * 0.3 + (math.cos(animationValue * 2 * math.pi + 0) * size.height * 0.1),
        opacity: 0.2,
        blurRadius: 80.0,
      ),
      BlobConfig(
        color: primaryColor,
        size: size.width * 0.35,
        centerX: size.width * 0.8 + (math.sin(animationValue * 2 * math.pi + math.pi) * size.width * 0.08),
        centerY: size.height * 0.7 + (math.cos(animationValue * 2 * math.pi + math.pi) * size.height * 0.08),
        opacity: 0.18,
        blurRadius: 70.0,
      ),
      
      // Medium accent blobs
      BlobConfig(
        color: accentColor,
        size: size.width * 0.25,
        centerX: size.width * 0.6 + (math.sin(animationValue * 2 * math.pi + math.pi * 0.5) * size.width * 0.12),
        centerY: size.height * 0.2 + (math.cos(animationValue * 2 * math.pi + math.pi * 0.5) * size.height * 0.12),
        opacity: 0.18,
        blurRadius: 50.0,
      ),
      BlobConfig(
        color: accentColor,
        size: size.width * 0.28,
        centerX: size.width * 0.1 + (math.sin(animationValue * 2 * math.pi + math.pi * 1.5) * size.width * 0.1),
        centerY: size.height * 0.8 + (math.cos(animationValue * 2 * math.pi + math.pi * 1.5) * size.height * 0.1),
        opacity: 0.15,
        blurRadius: 55.0,
      ),
      
      // Small accent blobs for sparkle effect
      BlobConfig(
        color: accentColor,
        size: size.width * 0.15,
        centerX: size.width * 0.9 + (math.sin(animationValue * 2 * math.pi + math.pi * 0.25) * size.width * 0.15),
        centerY: size.height * 0.15 + (math.cos(animationValue * 2 * math.pi + math.pi * 0.25) * size.height * 0.15),
        opacity: 0.18,
        blurRadius: 35.0,
      ),
      BlobConfig(
        color: primaryColor,
        size: size.width * 0.18,
        centerX: size.width * 0.4 + (math.sin(animationValue * 2 * math.pi + math.pi * 0.75) * size.width * 0.12),
        centerY: size.height * 0.9 + (math.cos(animationValue * 2 * math.pi + math.pi * 0.75) * size.height * 0.12),
        opacity: 0.15,
        blurRadius: 40.0,
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

    // Create organic blob shape using multiple circles with slight offsets
    final Path blobPath = Path();
    final double radius = config.size / 2;
    
    // Create an organic, irregular blob shape
    const int segments = 8;
    final List<Offset> points = [];
    
    for (int i = 0; i < segments; i++) {
      final double angle = (i / segments) * 2 * math.pi;
      final double radiusVariation = radius * (0.8 + 0.4 * math.sin(angle * 3 + animation.value * 2 * math.pi));
      final double x = config.centerX + radiusVariation * math.cos(angle);
      final double y = config.centerY + radiusVariation * math.sin(angle);
      points.add(Offset(x, y));
    }
    
    // Create smooth curves between points
    if (points.isNotEmpty) {
      blobPath.moveTo(points[0].dx, points[0].dy);
      
      for (int i = 0; i < points.length; i++) {
        final Offset current = points[i];
        final Offset next = points[(i + 1) % points.length];
        final Offset control1 = Offset(
          current.dx + (next.dx - current.dx) * 0.3,
          current.dy + (next.dy - current.dy) * 0.3,
        );
        final Offset control2 = Offset(
          current.dx + (next.dx - current.dx) * 0.7,
          current.dy + (next.dy - current.dy) * 0.7,
        );
        blobPath.cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, next.dx, next.dy);
      }
      
      blobPath.close();
    }

    canvas.drawPath(blobPath, blobPaint);
  }

  @override
  bool shouldRepaint(BlobPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
           oldDelegate.primaryColor != primaryColor ||
           oldDelegate.accentColor != accentColor;
  }
}

/// Configuration for a single animated blob
class BlobConfig {
  final Color color;
  final double size;
  final double centerX;
  final double centerY;
  final double opacity;
  final double blurRadius;

  const BlobConfig({
    required this.color,
    required this.size,
    required this.centerX,
    required this.centerY,
    required this.opacity,
    required this.blurRadius,
  });
}
