import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Utilities to compute contrast ratios and choose readable on-colors.
class ContrastUtils {
  const ContrastUtils._();

  static const double minAaTextContrast = 4.5; // WCAG AA for normal text
  static const double minAaUiContrast = 3.0; // Icons and non-text UI

  /// Returns the best on-color (black or white) for the given [background].
  static Color chooseOnColor(Color background) {
    final Brightness b = ThemeData.estimateBrightnessForColor(background);
    return b == Brightness.dark ? Colors.white : Colors.black;
  }

  /// Returns the contrast ratio between two colors (1.0 - 21.0).
  static double getContrastRatio(Color a, Color b) {
    final double l1 = _relativeLuminance(a);
    final double l2 = _relativeLuminance(b);
    final double bright = math.max(l1, l2);
    final double dark = math.min(l1, l2);
    return (bright + 0.05) / (dark + 0.05);
  }

  /// Try to ensure at least [minRatio] contrast by switching between black/white.
  /// This keeps computation cheap and avoids surprising hues.
  static Color ensureMinContrastBW(Color background, {double minRatio = minAaTextContrast}) {
    const Color whiteOn = Colors.white;
    const Color blackOn = Colors.black;
    final double whiteRatio = getContrastRatio(whiteOn, background);
    final double blackRatio = getContrastRatio(blackOn, background);
    if (whiteRatio >= blackRatio) {
      return whiteRatio >= minRatio ? whiteOn : (blackRatio > whiteRatio ? blackOn : whiteOn);
    } else {
      return blackRatio >= minRatio ? blackOn : (whiteRatio > blackRatio ? whiteOn : blackOn);
    }
  }

  static double _relativeLuminance(Color c) {
    final List<double> rgb = <int>[c.red, c.green, c.blue]
        .map((int channel) => channel / 255.0)
        .map((double value) => value <= 0.03928 ? value / 12.92 : math.pow((value + 0.055) / 1.055, 2.4).toDouble())
        .toList();
    return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2];
  }
}


