import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_data.dart';

class WeatherUtils {
  /// Determines weather icon asset path based on condition and time of day
  static String getWeatherIconAsset(String? condition, {bool isNight = false}) {
    if (condition == null) return 'assets/weather_icons/clear.png';
    final c = condition.toLowerCase();

    if (c.contains('clear') || c.contains('sunny')) {
      return isNight ? 'assets/weather_icons/night_clear.png' : 'assets/weather_icons/clear.png';
    } else if (c.contains('partly') && c.contains('cloud')) {
      return isNight ? 'assets/weather_icons/night_partly_cloudy.png' : 'assets/weather_icons/partly_cloudy.png';
    } else if (c.contains('cloud')) {
      return 'assets/weather_icons/cloudy.png';
    } else if (c.contains('rain') || c.contains('shower')) {
      return 'assets/weather_icons/rain.png';
    } else if (c.contains('thunder')) {
      return 'assets/weather_icons/thunderstorm.png';
    } else if (c.contains('snow')) {
      return 'assets/weather_icons/snow.png';
    } else if (c.contains('sleet') || c.contains('freezing')) {
      return 'assets/weather_icons/sleet.png';
    } else if (c.contains('fog') || c.contains('mist') || c.contains('haze')) {
      return 'assets/weather_icons/fog.png';
    } else if (c.contains('wind')) {
      return 'assets/weather_icons/windy.png';
    }

    return 'assets/weather_icons/clear.png';
  }

  /// Get high and low temperatures from the forecast data for today
  static Map<String, int?> getTodayHighLow(List<ForecastPeriod> forecast) {
    int? high;
    int? low;

    // Get today's date in the format 'yyyy-MM-dd'
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (var period in forecast) {
      // Only consider periods for today
      final periodDate = DateFormat('yyyy-MM-dd').format(period.startTime);
      if (periodDate != today) continue;

      // Update high temperature from daytime periods
      if (period.isDaytime && (high == null || period.temperature > high)) {
        high = period.temperature;
      }

      // Update low temperature from nighttime periods
      if (!period.isDaytime && (low == null || period.temperature < low)) {
        low = period.temperature;
      }
    }

    // If we don't have both values from today's forecast, include tomorrow morning/night
    if (high == null || low == null) {
      final tomorrow = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)));

      for (var period in forecast) {
        final periodDate = DateFormat('yyyy-MM-dd').format(period.startTime);
        if (periodDate != tomorrow) continue;

        // If we don't have a high yet, use tomorrow's day temperature
        if (high == null && period.isDaytime) {
          high = period.temperature;
        }

        // If we don't have a low yet, use tomorrow's night temperature
        if (low == null && !period.isDaytime) {
          low = period.temperature;
        }
      }
    }

    return {'high': high, 'low': low};
  }

  /// Get sunrise and sunset times from the Google Weather API forecast data
  static Map<String, DateTime?> getSunriseSunset(List<ForecastPeriod> forecast) {
    // Find the first period with sunrise/sunset info (should be the first Day period of the first forecast day)
    for (final period in forecast) {
      if (period.sunriseTime != null && period.sunsetTime != null) {
        return {
          'sunrise': period.sunriseTime,
          'sunset': period.sunsetTime,
        };
      }
    }
    // If not found, fallback to nulls
    return {'sunrise': null, 'sunset': null};
  }

  /// Map weather condition to background gradient colors
  static List<Color> getGradientForCondition(String? condition) {
    if (condition == null) {
      // Default (Clear)
      return [const Color(0xFF23235B), const Color(0xFF6D3CA4), const Color(0xFFFF7E5F)];
    }

    final c = condition.toLowerCase();

    if (c.contains('clear') || c.contains('sunny')) {
      return [const Color(0xFF23235B), const Color(0xFF6D3CA4), const Color(0xFFFF7E5F)];
    } else if (c.contains('partly') || c.contains('mostly') && c.contains('cloud')) {
      return [const Color(0xFF3A3D5C), const Color(0xFF7B5EA7), const Color(0xFFF7B2B7)];
    } else if (c.contains('cloud')) {
      return [const Color(0xFF43455C), const Color(0xFF8A7CA8)];
    } else if (c.contains('rain') || c.contains('shower') || c.contains('thunder')) {
      return [const Color(0xFF23235B), const Color(0xFF3A5BA0), const Color(0xFF7B8FA3)];
    } else if (c.contains('snow') || c.contains('sleet')) {
      return [const Color(0xFF3A5BA0), const Color(0xFFA3C9F7), const Color(0xFFFFFFFF)];
    } else if (c.contains('fog') || c.contains('mist') || c.contains('haze')) {
      return [const Color(0xFF6E7B8B), const Color(0xFFB0B8C1)];
    }

    // Fallback
    return [const Color(0xFF23235B), const Color(0xFF6D3CA4), const Color(0xFFFF7E5F)];
  }

  /// Group forecast periods by date, separating day and night
  static Map<String, Map<String, ForecastPeriod?>> groupForecastByDate(List<ForecastPeriod> forecast) {
    final Map<String, Map<String, ForecastPeriod?>> forecastByDate = {};

    for (var period in forecast) {
      final dateStr = DateFormat('yyyy-MM-dd').format(period.startTime);

      // Initialize the date entry if it doesn't exist
      if (!forecastByDate.containsKey(dateStr)) {
        forecastByDate[dateStr] = {
          'day': null,
          'night': null,
        };
      }

      // Store period in appropriate slot
      if (period.isDaytime) {
        forecastByDate[dateStr]!['day'] = period;
      } else {
        forecastByDate[dateStr]!['night'] = period;
      }
    }

    return forecastByDate;
  }
}
