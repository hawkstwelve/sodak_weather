import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide styling and theme configuration
class AppTheme {
  AppTheme._(); // Private constructor to prevent instantiation

  // Primary colors
  static const Color primaryDark = Color(0xFF23235B);
  static const Color primaryMedium = Color(0xFF6D3CA4);
  static const Color primaryLight = Color(0xFFFF7E5F);

  // Weather condition colors
  static const Color clearNight = Color(0xFF23235B);
  static const Color clearDay = Color(0xFF6D3CA4);
  static const Color cloudyDark = Color(0xFF43455C);
  static const Color cloudyLight = Color(0xFF8A7CA8);
  static const Color partlyCloudyDark = Color(0xFF3A3D5C);
  static const Color partlyCloudyMedium = Color(0xFF7B5EA7);
  static const Color partlyCloudyLight = Color(0xFFF7B2B7);
  static const Color rainyDark = Color(0xFF23235B);
  static const Color rainyMedium = Color(0xFF3A5BA0);
  static const Color rainyLight = Color(0xFF7B8FA3);
  static const Color snowDark = Color(0xFF3A5BA0);
  static const Color snowMedium = Color(0xFFA3C9F7);
  static const Color snowLight = Color(0xFFFFFFFF);
  static const Color fogDark = Color(0xFF6E7B8B);
  static const Color fogLight = Color(0xFFB0B8C1);

  // Text colors
  static const Color textLight = Colors.white;
  static const Color textMedium = Color(0xB3FFFFFF); // white with 70% opacity
  static const Color textDark = Color(0xFF333333);
  static const Color textBlue = Color(0xFF64B5F6); // light blue for links/buttons
  static const Color textYellow = Color(0xFFFFEB3B); // yellow for daytime indicators

  // Glass card colors
  static const Color glassCardColor = Color(0x2EFFFFFF); // white with 18% opacity
  static const Color glassShadowColor = Color(0x142196F3); // blue with 8% opacity

  // Icon colors
  static const Color iconDay = Color(0xFFFFF176); // light yellow
  static const Color iconNight = Color(0xFF90CAF9); // light blue

  // Card background color
  static const Color cardBackground = glassCardColor;

  // Get gradient colors based on weather condition
  static List<Color> getGradientForCondition(String? condition) {
    if (condition == null) {
      // Default (Clear)
      return [primaryDark, primaryMedium, primaryLight];
    }

    final c = condition.toLowerCase();
    if (c.contains('clear') || c.contains('sunny')) {
      return [primaryDark, primaryMedium, primaryLight];
    } else if (c.contains('partly') || c.contains('mostly') && c.contains('cloud')) {
      return [partlyCloudyDark, partlyCloudyMedium, partlyCloudyLight];
    } else if (c.contains('cloud')) {
      return [cloudyDark, cloudyLight];
    } else if (c.contains('rain') || c.contains('shower') || c.contains('thunder')) {
      return [rainyDark, rainyMedium, rainyLight];
    } else if (c.contains('snow') || c.contains('sleet')) {
      return [snowDark, snowMedium, snowLight];
    } else if (c.contains('fog') || c.contains('mist') || c.contains('haze')) {
      return [fogDark, fogLight];
    }

    // Fallback
    return [primaryDark, primaryMedium, primaryLight];
  }

  // Text styles
  static TextStyle get headingLarge => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textLight,
  );

  static TextStyle get headingMedium => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: textLight,
  );

  static TextStyle get headingSmall => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textLight,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textLight,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textMedium,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textMedium,
  );

  static TextStyle get bodyBold => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: textLight,
  );

  static TextStyle get temperature => GoogleFonts.inter(
    fontSize: 64,
    fontWeight: FontWeight.bold,
    color: textLight,
  );

  // Create the app theme
  static ThemeData get theme => ThemeData(
    primaryColor: primaryMedium,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryMedium,
      brightness: Brightness.dark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textLight,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textLight,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: textBlue,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryMedium,
        foregroundColor: textLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.inter(color: textLight, fontSize: 64, fontWeight: FontWeight.bold),
      headlineLarge: GoogleFonts.inter(color: textLight, fontSize: 28, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.inter(color: textLight, fontSize: 24, fontWeight: FontWeight.bold),
      headlineSmall: GoogleFonts.inter(color: textLight, fontSize: 20, fontWeight: FontWeight.bold),
      bodyLarge: GoogleFonts.inter(color: textLight, fontSize: 16),
      bodyMedium: GoogleFonts.inter(color: textMedium, fontSize: 14),
      bodySmall: GoogleFonts.inter(color: textMedium, fontSize: 12),
    ),
  );
}
