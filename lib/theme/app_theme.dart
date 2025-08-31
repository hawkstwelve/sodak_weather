import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sodak_weather/models/theme_config.dart';
import 'package:sodak_weather/utils/contrast_utils.dart';

/// App-wide styling and theme configuration
class AppTheme {
  AppTheme._(); // Private constructor to prevent instantiation

  // Primary colors
  static const Color primaryDark = Color(0xFF23235B);
  static const Color primaryMedium = Color(0xFF6D3CA4);
  static const Color primaryLight = Color(0xFFFF7E5F);

  // Weather condition colors (legacy) — removed in favor of ColorScheme; kept temporarily for backward compatibility
  @Deprecated('Legacy condition colors removed. Use Theme.of(context).colorScheme instead.')
  static const Color clearNight = Color(0xFF23235B);
  @Deprecated('Legacy condition colors removed. Use Theme.of(context).colorScheme instead.')
  static const Color clearDay = Color(0xFF6D3CA4);
  @Deprecated('Legacy condition colors removed. Use Theme.of(context).colorScheme instead.')
  static const Color cloudyDark = Color(0xFF43455C);
  @Deprecated('Legacy condition colors removed. Use Theme.of(context).colorScheme instead.')
  static const Color cloudyLight = Color(0xFF8A7CA8);
  @Deprecated('Legacy condition colors removed. Use Theme.of(context).colorScheme instead.')
  static const Color partlyCloudyDark = Color(0xFF3A3D5C);
  @Deprecated('Legacy condition colors removed. Use Theme.of(context).colorScheme instead.')
  static const Color partlyCloudyMedium = Color(0xFF7B5EA7);
  @Deprecated('Legacy condition colors removed. Use Theme.of(context).colorScheme instead.')
  static const Color partlyCloudyLight = Color(0xFFF7B2B7);
  @Deprecated('Legacy condition colors removed. Use Theme.of(context).colorScheme instead.')
  static const Color rainyDark = Color(0xFF23235B);
  @Deprecated('Legacy condition colors removed. Use Theme.of(context).colorScheme instead.')
  static const Color rainyMedium = Color(0xFF3A5BA0);
  @Deprecated('Legacy condition colors removed. Use Theme.of(context).colorScheme instead.')
  static const Color rainyLight = Color(0xFF7B8FA3);
  @Deprecated('Legacy condition colors removed. Use Theme.of(context).colorScheme instead.')
  static const Color snowDark = Color(0xFF3A5BA0);
  @Deprecated('Legacy condition colors removed. Use Theme.of(context).colorScheme instead.')
  static const Color snowMedium = Color(0xFFA3C9F7);
  @Deprecated('Legacy condition colors removed. Use Theme.of(context).colorScheme instead.')
  static const Color snowLight = Color(0xFFFFFFFF);
  @Deprecated('Legacy condition colors removed. Use Theme.of(context).colorScheme instead.')
  static const Color fogDark = Color(0xFF6E7B8B);
  @Deprecated('Legacy condition colors removed. Use Theme.of(context).colorScheme instead.')
  static const Color fogLight = Color(0xFFB0B8C1);

  // Text colors (legacy token references)—prefer textTheme & colorScheme
  @Deprecated('Use Theme.of(context).colorScheme.onSurface and textTheme')
  static const Color textLight = Colors.white;
  @Deprecated('Use Theme.of(context).colorScheme.onSurface with opacity')
  static const Color textMedium = Color(0xB3FFFFFF);
  @Deprecated('Use Theme.of(context).colorScheme.onSurface')
  static const Color textDark = Color(0xFF333333);
  @Deprecated('Use Theme.of(context).colorScheme.primary')
  static const Color textBlue = Color(0xFF64B5F6);
  @Deprecated('Use Theme.of(context).colorScheme.tertiary or secondary')
  static const Color textYellow = Color(0xFFFFEB3B);

  // Glass card colors (legacy) — superseded by GlassThemeExtension
  @Deprecated('Use GlassThemeExtension from Theme')
  static const Color glassCardColor = Color(0x2EFFFFFF);
  @Deprecated('Use GlassThemeExtension from Theme')
  static const Color glassShadowColor = Color(0x142196F3);

  // Loading indicator color (legacy) — use theme colorScheme.onSurface
  @Deprecated('Use Theme.of(context).colorScheme.onSurface.withOpacity(0.6)')
  static const Color loadingIndicatorColor = Color(0x4DFFFFFF);

  // Icon colors
  static const Color iconDay = Color(0xFFFFF176); // light yellow
  static const Color iconNight = Color(0xFF90CAF9); // light blue

  // Card background color
  static const Color cardBackground = glassCardColor;

  // Deprecated: weather-based gradients — fully removed in PR6

  // Deprecated: Text styles - Use Theme.of(context).textTheme instead
  @Deprecated('Use Theme.of(context).textTheme.headlineLarge instead')
  static TextStyle get headingLarge => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textLight,
  );

  @Deprecated('Use Theme.of(context).textTheme.headlineMedium instead')
  static TextStyle get headingMedium => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: textLight,
  );

  @Deprecated('Use Theme.of(context).textTheme.headlineSmall instead')
  static TextStyle get headingSmall => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textLight,
  );

  @Deprecated('Use Theme.of(context).textTheme.bodyLarge instead')
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textLight,
  );

  @Deprecated('Use Theme.of(context).textTheme.bodyMedium instead')
  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textMedium,
  );

  @Deprecated('Use Theme.of(context).textTheme.bodySmall instead')
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textMedium,
  );

  @Deprecated('Use Theme.of(context).textTheme.bodyMedium with fontWeight: FontWeight.bold instead')
  static TextStyle get bodyBold => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: textLight,
  );

  @Deprecated('Use Theme.of(context).textTheme.displayLarge with custom fontSize instead')
  static TextStyle get temperature => GoogleFonts.inter(
    fontSize: 64,
    fontWeight: FontWeight.bold,
    color: textLight,
  );

  // Glass theme extension tokens for beautiful frosted glass effect
  // Matches modern glassmorphism design with proper transparency and blur
  static GlassThemeExtension buildGlassTokens(ThemeConfig config) {
    const double blurSigma = 20.0; // Optimal blur for frosted effect
    const double opacity = 0.0; // Completely transparent for debugging
    const double borderOpacity = 0.3; // Subtle white borders for glass edge
    const double shadowOpacity = 0.25; // Gentle white shadows for floating effect
    
    return GlassThemeExtension(
      backgroundColor: Colors.white.withValues(alpha: 0.25), // Increased from 0.1 to 0.25 for better text visibility
      borderColor: Colors.white.withValues(alpha: borderOpacity), // White borders for frosted look
      shadowColor: Colors.white.withValues(alpha: shadowOpacity), // White shadows for glass effect
      tintColor: config.primary, // Primary color for subtle tinting
      opacity: opacity,
      blurSigma: blurSigma,
    );
  }

  // Build a unified ColorScheme for the single theme
  static ColorScheme _buildScheme(ThemeConfig config) {
    // Create a light theme base with primary color
    ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: config.primary, 
      brightness: Brightness.light,
    );
    
    // Apply accent color to secondary and tertiary
    scheme = scheme.copyWith(
      secondary: config.accent,
      tertiary: config.accent,
      // Use white text for better visibility on colorful background
      onSurface: Colors.white, // White text for readability on colorful animated background
      onPrimary: Colors.white,
    );
    
    final Color adjustedOnSecondary = ContrastUtils.ensureMinContrastBW(scheme.secondary, minRatio: ContrastUtils.minAaUiContrast);
    final Color adjustedOnTertiary = ContrastUtils.ensureMinContrastBW(scheme.tertiary, minRatio: ContrastUtils.minAaUiContrast);
    
    return scheme.copyWith(
      onSecondary: adjustedOnSecondary,
      onTertiary: adjustedOnTertiary,
    );
  }

  // Build text theme using Inter and appropriate on-surface colors
  static TextTheme _buildTextTheme(ColorScheme scheme) {
    final TextTheme base = GoogleFonts.interTextTheme();
    return base.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
  }

  static ThemeData buildTheme(ThemeConfig config) {
    final ColorScheme scheme = _buildScheme(config);
    final TextTheme textTheme = _buildTextTheme(scheme);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent, // Transparent to show frosted blob background
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      textTheme: textTheme,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: ContrastUtils.ensureMinContrastBW(scheme.primary, minRatio: ContrastUtils.minAaUiContrast),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 8,
          shadowColor: scheme.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        buildGlassTokens(config),
      ],
    );
  }


}

/// Theme extension carrying glassmorphism tokens used by glass widgets
class GlassThemeExtension extends ThemeExtension<GlassThemeExtension> {
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final Color tintColor;
  final double opacity;
  final double blurSigma;

  const GlassThemeExtension({
    required this.backgroundColor,
    required this.borderColor,
    required this.shadowColor,
    required this.tintColor,
    required this.opacity,
    required this.blurSigma,
  });

  @override
  GlassThemeExtension copyWith({
    Color? backgroundColor,
    Color? borderColor,
    Color? shadowColor,
    Color? tintColor,
    double? opacity,
    double? blurSigma,
  }) {
    return GlassThemeExtension(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      shadowColor: shadowColor ?? this.shadowColor,
      tintColor: tintColor ?? this.tintColor,
      opacity: opacity ?? this.opacity,
      blurSigma: blurSigma ?? this.blurSigma,
    );
  }

  @override
  GlassThemeExtension lerp(ThemeExtension<GlassThemeExtension>? other, double t) {
    if (other is! GlassThemeExtension) return this;
    return GlassThemeExtension(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t) ?? backgroundColor,
      borderColor: Color.lerp(borderColor, other.borderColor, t) ?? borderColor,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t) ?? shadowColor,
      tintColor: Color.lerp(tintColor, other.tintColor, t) ?? tintColor,
      opacity: opacity + (other.opacity - opacity) * t,
      blurSigma: blurSigma + (other.blurSigma - blurSigma) * t,
    );
  }
}

