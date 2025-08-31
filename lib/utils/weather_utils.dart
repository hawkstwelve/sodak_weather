import 'package:intl/intl.dart';
import '../models/weather_data.dart';

class WeatherUtils {
  /// Determines weather icon asset path based on condition and time of day
  static String getWeatherIconAsset(String? condition, {bool isNight = false}) {
    if (condition == null) return 'assets/weather_icons/clear.png';
    final c = condition.toLowerCase();

    if (c.contains('partly') && c.contains('sunny')) {
      return isNight ? 'assets/weather_icons/night_partly_cloudy.png' : 'assets/weather_icons/partly_cloudy.png';
    } else if (c.contains('clear') || c.contains('sunny')) {
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

  // Deprecated API removed: getGradientForCondition

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

  /// Convert wind direction degrees to cardinal direction (N, NE, E, SE, S, SW, W, NW)
  static String getWindDirection(int? degrees) {
    if (degrees == null) return '';
    
    // Normalize degrees to 0-360 range
    final normalized = degrees % 360;
    
    // Define cardinal directions with their degree ranges
    if (normalized >= 337.5 || normalized < 22.5) return 'N';
    if (normalized >= 22.5 && normalized < 67.5) return 'NE';
    if (normalized >= 67.5 && normalized < 112.5) return 'E';
    if (normalized >= 112.5 && normalized < 157.5) return 'SE';
    if (normalized >= 157.5 && normalized < 202.5) return 'S';
    if (normalized >= 202.5 && normalized < 247.5) return 'SW';
    if (normalized >= 247.5 && normalized < 292.5) return 'W';
    if (normalized >= 292.5 && normalized < 337.5) return 'NW';
    
    return 'N'; // Fallback
  }

  /// Format wind information with direction, speed, and gusts
  /// Returns format: "NW 10\nG 20 mph" or "NW 10 mph" if no gusts
  static String formatWind({
    required int? windDirection,
    required double? windSpeedMph,
    required double? windGustMph,
  }) {
    final direction = getWindDirection(windDirection);
    final speed = windSpeedMph?.round();
    
    if (speed == null) return 'N/A';
    
    final baseString = '$direction $speed';
    
    // Add gust information if available and different from wind speed
    if (windGustMph != null && windGustMph > (windSpeedMph ?? 0)) {
      final gust = windGustMph.round();
      return '$baseString\nG $gust mph';
    }
    
    return '$baseString mph';
  }

  /// Convert UV index value to descriptive string
  static String uvIndexDescription(int? uvIndex) {
    if (uvIndex == null) return 'N/A';
    if (uvIndex <= 2) return 'Low';
    if (uvIndex <= 5) return 'Moderate';
    if (uvIndex <= 7) return 'High';
    if (uvIndex <= 10) return 'Very High';
    return 'Extreme';
  }
}
