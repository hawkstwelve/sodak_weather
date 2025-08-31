import 'package:flutter/material.dart';

/// UI Constants for the Sodak Weather App
/// 
/// This file contains all the magic numbers used throughout the UI
/// to ensure consistency and maintainability.
class UIConstants {
  UIConstants._(); // Private constructor to prevent instantiation

  // Opacity values
  static const double opacityVeryLow = 0.2;
  static const double opacityLow = 0.3;
  static const double opacityMedium = 0.4;
  static const double opacityHigh = 0.7;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 350);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration delayShort = Duration(milliseconds: 500);
  static const Duration delayMedium = Duration(milliseconds: 1000);
  static const Duration delayLong = Duration(milliseconds: 2000);

  // Spacing values
  static const double spacingTiny = 2.0;
  static const double spacingSmall = 4.0;
  static const double spacingMedium = 6.0;
  static const double spacingStandard = 8.0;
  static const double spacingLarge = 12.0;
  static const double spacingXLarge = 16.0;
  static const double spacingXXLarge = 20.0;
  static const double spacingXXXLarge = 24.0;
  static const double spacingHuge = 32.0;

  // Icon sizes
  static const double iconSizeSmall = 14.0;
  static const double iconSizeMedium = 32.0;
  static const double iconSizeLarge = 72.0;
  static const double iconSizeHourlyForecast = 40.0; // Specific size for hourly forecast weather icons

  // Card dimensions
  static const double cardHeightSmall = 100.0;
  static const double cardHeightMedium = 140.0;
  static const double cardHeightLarge = 160.0;
  static const double cardHeightXLarge = 200.0;
  static const double cardHeightXXLarge = 220.0;

  // Chart dimensions
  static const double chartHeight = 200.0;
  static const double chartMaxHeight = 400.0;

  // Divider dimensions
  static const double dividerHeight = 1.0;
  static const double dividerHeightLarge = 32.0;

  // Marker dimensions
  static const double markerSize = 4.0;
  static const double mapMarkerSize = 24.0; // Size for map location markers
  static const double legendIconSize = 10.0;

  // Text field dimensions
  static const double textFieldHeight = 56.0;

  // Border radius - standardized to 20px for modern consistency
  static const double borderRadiusSmall = 12.0;
  static const double borderRadiusStandard = 26.0;
  static const double borderRadiusLarge = 28.0;
  
  // Elevation values for floating appearance
  static const double elevationSubtle = 4.0;
  static const double elevationModerate = 8.0;
  static const double elevationProminent = 16.0;

  // Frosted glass gradient
  static const List<Color> frostedGradient = [Color(0x30FFFFFF), Color(0x20FFFFFF)];
} 