/// Service Constants for the Sodak Weather App
/// 
/// This file contains all the magic numbers used in services,
/// API calls, and business logic.
class ServiceConstants {
  ServiceConstants._(); // Private constructor to prevent instantiation

  // Cache durations
  static const int cacheDurationMinutes = 10;
  static const int cacheDurationMs = cacheDurationMinutes * 60 * 1000;

  // Timeout values
  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration retryDelay = Duration(milliseconds: 500);

  // Retry attempts
  static const int maxRetries = 2;

  // API parameters
  static const int forecastDays = 10;
  static const int forecastHours = 24;
  static const int historyHours = 24;

  // Default coordinates (Sioux Falls, SD)
  static const double defaultLatitude = 43.5446;
  static const double defaultLongitude = -96.7311;

  // Radar settings
  static const double radarOpacity = 0.7;
  static const double radarInitialZoom = 8.5;
  static const double radarMinZoom = 3.0;
  static const double radarMaxZoom = 14.0;

  // Refresh intervals
  static const Duration weatherRefreshInterval = Duration(minutes: 5);
  static const Duration locationRefreshInterval = Duration(minutes: 10);

  // Cache versions
  static const String cacheVersion = 'v3';
} 