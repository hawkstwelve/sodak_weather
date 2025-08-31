import 'package:flutter/material.dart';

/// Configuration object that represents the user-selected theme settings
/// Simplified to focus on color customization only
class ThemeConfig {
  final Color primary;
  final Color accent;

  const ThemeConfig({
    required this.primary,
    required this.accent,
  });

  factory ThemeConfig.defaults() {
    return const ThemeConfig(
      primary: Color(0xFF6D3CA4), // Beautiful purple
      accent: Color(0xFFFF7E5F),  // Warm coral
    );
  }

  ThemeConfig copyWith({
    Color? primary,
    Color? accent,
  }) {
    return ThemeConfig(
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
    );
  }

  Map<String, Object> toMap() {
    return {
      'primary': primary.toARGB32(),
      'accent': accent.toARGB32(),
    };
  }

  static ThemeConfig fromMap(Map<String, Object?> map) {
    final int primaryValue = (map['primary'] as int?) ?? const Color(0xFF6D3CA4).value;
    final int accentValue = (map['accent'] as int?) ?? const Color(0xFFFF7E5F).value;
    return ThemeConfig(
      primary: Color(primaryValue),
      accent: Color(accentValue),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeConfig &&
        other.primary.toARGB32() == primary.toARGB32() &&
        other.accent.toARGB32() == accent.toARGB32();
  }

  @override
  int get hashCode {
    return Object.hash(primary.toARGB32(), accent.toARGB32());
  }
}


