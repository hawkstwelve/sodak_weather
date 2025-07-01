import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sd_city.dart';
import '../models/hourly_forecast.dart';
import '../models/weather_data.dart';
import '../config/api_config.dart';
import '../constants/service_constants.dart';

class WeatherService {
  static const String _baseUrl = 'https://weather.googleapis.com/v1';
  static const int cacheDurationMs = 10 * 60 * 1000; // 10 minutes
  static const String _cacheVersion = 'v3';

  // Default to Sioux Falls, SD coordinates
  static const double _defaultLatitude = ServiceConstants.defaultLatitude;
  static const double _defaultLongitude = ServiceConstants.defaultLongitude;

  Map<String, dynamic>? lastRawForecastData;

  http.Client _createHttpClient() {
    return http.Client();
  }

  Future<http.Response> _makeHttpRequest(Uri url, {Map<String, String>? headers, Object? body, String method = 'GET'}) async {
    return await _retry(() async {
      final client = _createHttpClient();
      try {
        if (method == 'POST') {
          return await client.post(url, headers: headers, body: body).timeout(ServiceConstants.requestTimeout);
        } else {
          return await client.get(url, headers: headers).timeout(ServiceConstants.requestTimeout);
        }
      } on SocketException catch (_) {
        throw Exception('Network connection failed. Please check your internet connection.');
      } on HandshakeException catch (_) {
        throw Exception('Secure connection failed. Please try again.');
      } on TimeoutException catch (_) {
        throw Exception('Request timed out. Please try again.');
      } catch (_) {
        throw Exception('An unexpected error occurred. Please try again.');
      } finally {
        client.close();
      }
    });
  }

  Future<T> _retry<T>(Future<T> Function() fn) async {
    int attempt = 0;
    while (true) {
      try {
        return await fn();
      } catch (e) {
        attempt++;
        if (attempt > ServiceConstants.maxRetries) rethrow;
        await Future.delayed(ServiceConstants.retryDelay);
      }
    }
  }

  Future<Map<String, dynamic>?> getCurrentWeather({SDCity? city, double? latitude, double? longitude}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cityKey = city?.name ?? (latitude != null && longitude != null ? '${latitude}_$longitude' : 'default');
      final cacheKey = 'currentWeather_${ServiceConstants.cacheVersion}_$cityKey';
      final cacheTimeKey = '${cacheKey}_time';
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check cache
      final cached = prefs.getString(cacheKey);
      final cachedTime = prefs.getInt(cacheTimeKey);
      if (cached != null && cachedTime != null && now - cachedTime < ServiceConstants.cacheDurationMs) {
        return json.decode(cached);
      }

      // Google Weather API: Current Conditions
      final double lat = latitude ?? city?.latitude ?? _defaultLatitude;
      final double lon = longitude ?? city?.longitude ?? _defaultLongitude;
      final currentUrl = Uri.parse(
        '$_baseUrl/currentConditions:lookup?location.latitude=$lat&location.longitude=$lon&unitsSystem=IMPERIAL&key=${ApiConfig.googleApiKey}',
      );
      final currentResponse = await _makeHttpRequest(currentUrl);
      if (currentResponse.statusCode != 200) {
        throw Exception('Failed to get current conditions: ${currentResponse.statusCode}');
      }
      final currentData = json.decode(currentResponse.body);

      // Google Weather API: Forecast (10 days)
      final forecastUrl = Uri.parse(
        '$_baseUrl/forecast/days:lookup?location.latitude=$lat&location.longitude=$lon&unitsSystem=IMPERIAL&days=${ServiceConstants.forecastDays}&pageSize=${ServiceConstants.forecastDays}&key=${ApiConfig.googleApiKey}',
      );
      final forecastResponse = await _makeHttpRequest(forecastUrl);
      if (forecastResponse.statusCode != 200) {
        throw Exception('Failed to get forecast: ${forecastResponse.statusCode}');
      }
      final forecastData = json.decode(forecastResponse.body);

      // Store the raw forecast data for sunrise/sunset utility
      lastRawForecastData = forecastData;

      final result = {'currentConditions': currentData, 'forecast': forecastData};
      // Store in cache
      prefs.setString(cacheKey, json.encode(result));
      prefs.setInt(cacheTimeKey, now);
      return result;
    } catch (e) {
      throw Exception('Error in getCurrentWeather: $e');
    }
  }

  Future<int?> fetchAqi({
    required double latitude,
    required double longitude,
    SDCity? city,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cityKey = city?.name ?? '${latitude}_$longitude';
      final cacheKey = 'aqi_${_cacheVersion}_$cityKey';
      final cacheTimeKey = '${cacheKey}_time';
      final now = DateTime.now().millisecondsSinceEpoch;

      final cached = prefs.getString(cacheKey);
      final cachedTime = prefs.getInt(cacheTimeKey);
      if (cached != null && cachedTime != null && now - cachedTime < cacheDurationMs) {
        return int.tryParse(cached);
      }

      final url = Uri.parse(
        'https://airquality.googleapis.com/v1/currentConditions:lookup?key=${ApiConfig.googleApiKey}',
      );
      final response = await _makeHttpRequest(
        url, 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'location': {'latitude': latitude, 'longitude': longitude},
        }),
        method: 'POST',
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch AQI: ${response.statusCode}');
      }
      final data = json.decode(response.body);
      int? aqi;
      if (data['indexes'] != null &&
          data['indexes'] is List &&
          data['indexes'].isNotEmpty) {
        aqi = data['indexes'][0]['aqi'] as int?;
      }
      if (aqi != null) {
        prefs.setString(cacheKey, aqi.toString());
        prefs.setInt(cacheTimeKey, now);
      }
      return aqi;
    } catch (e) {
      throw Exception('Error in fetchAqi: $e');
    }
  }

  Future<Map<String, String?>?> fetchAqiCategory({
    required double latitude,
    required double longitude,
    SDCity? city,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cityKey = city?.name ?? '${latitude}_$longitude';
      final cacheKey = 'aqiCategory_${_cacheVersion}_$cityKey';
      final cacheTimeKey = '${cacheKey}_time';
      final now = DateTime.now().millisecondsSinceEpoch;

      final cached = prefs.getString(cacheKey);
      final cachedTime = prefs.getInt(cacheTimeKey);
      if (cached != null && cachedTime != null && now - cachedTime < cacheDurationMs) {
        return Map<String, String?>.from(json.decode(cached));
      }

      final url = Uri.parse(
        'https://airquality.googleapis.com/v1/currentConditions:lookup?key=${ApiConfig.googleApiKey}',
      );
      final response = await _makeHttpRequest(
        url, 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'location': {'latitude': latitude, 'longitude': longitude},
        }),
        method: 'POST',
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch AQI category: ${response.statusCode}');
      }
      final data = json.decode(response.body);
      String? aqi;
      String? category;
      if (data['indexes'] != null &&
          data['indexes'] is List &&
          data['indexes'].isNotEmpty) {
        aqi = data['indexes'][0]['aqi']?.toString();
        category = data['indexes'][0]['category'] as String?;
      }
      final result = {'aqi': aqi, 'category': category};
      prefs.setString(cacheKey, json.encode(result));
      prefs.setInt(cacheTimeKey, now);
      return result;
    } catch (e) {
      throw Exception('Error in fetchAqiCategory: $e');
    }
  }

  Map<String, dynamic>? extractCurrentConditions(
    Map<String, dynamic> weatherData,
  ) {
    final current = weatherData['currentConditions'];
    if (current == null) return null;
    final weatherCondition = current['weatherCondition'] ?? {};
    // Extract precipitation (last hour) and uvIndex
    final uvIndex = current['uvIndex'];
    final precip = current['precipitation']?['qpf']?['quantity'];
    final precipUnit = current['precipitation']?['qpf']?['unit'];
    
    return {
      'temperature': current['temperature']?['degrees'],
      'apparentTemperature': current['feelsLikeTemperature']?['degrees'],
      'dewpoint': current['dewPoint']?['degrees'],
      'humidity': current['relativeHumidity'],
      'windSpeed': current['wind']?['speed']?['value'],
      'windGust': current['wind']?['gust']?['value'],
      'windDirection': current['wind']?['direction']?['degrees'],
      'pressure': current['airPressure']?['meanSeaLevelMillibars'],
      'visibility': current['visibility']?['distance'],
      'textDescription': weatherCondition['description']?['text'],
      'timestamp': current['currentTime'],
      'uvIndex': uvIndex,
      'precip1h': precip,
      'precip1hUnit': precipUnit,
    };
  }

  List<Map<String, dynamic>> extractForecast(Map<String, dynamic> weatherData) {
    try {
      final forecastDays = weatherData['forecast']['forecastDays'] as List?;
      if (forecastDays == null) return [];
      List<Map<String, dynamic>> periods = [];
      for (var day in forecastDays) {
        // Daytime
        final dayPart = day['daytimeForecast'] ?? {};
        final weatherCondition = dayPart['weatherCondition'] ?? {};
        periods.add({
          'name': 'Day',
          'temperature': day['maxTemperature']?['degrees'],
          'temperatureUnit': day['maxTemperature']?['unit'],
          'windSpeed': dayPart['wind']?['speed']?['value'],
          'windDirection': dayPart['wind']?['direction']?['degrees'],
          'precipProbability':
              dayPart['precipitation']?['probability']?['percent'],
          'cloudCover': dayPart['cloudCover'],
          'shortForecast': weatherCondition['description']?['text'],
          'detailedForecast': weatherCondition['description']?['text'],
          'icon': weatherCondition['iconBaseUri'],
          'startTime': day['interval']?['startTime'],
          'endTime': day['interval']?['endTime'],
          'isDaytime': true,
          'sunriseTime': day['sunEvents']?['sunriseTime'],
          'sunsetTime': day['sunEvents']?['sunsetTime'],
          'thunderstormProbability': dayPart['thunderstormProbability'],
        });
        // Nighttime
        final nightPart = day['nighttimeForecast'] ?? {};
        final nightWeatherCondition = nightPart['weatherCondition'] ?? {};
        periods.add({
          'name': 'Night',
          'temperature': day['minTemperature']?['degrees'],
          'temperatureUnit': day['minTemperature']?['unit'],
          'windSpeed': nightPart['wind']?['speed']?['value'],
          'windDirection': nightPart['wind']?['direction']?['degrees'],
          'precipProbability':
              nightPart['precipitation']?['probability']?['percent'],
          'cloudCover': nightPart['cloudCover'],
          'shortForecast': nightWeatherCondition['description']?['text'],
          'detailedForecast': nightWeatherCondition['description']?['text'],
          'icon': nightWeatherCondition['iconBaseUri'],
          'startTime': day['interval']?['startTime'],
          'endTime': day['interval']?['endTime'],
          'isDaytime': false,
          'sunriseTime': day['sunEvents']?['sunriseTime'],
          'sunsetTime': day['sunEvents']?['sunsetTime'],
          'thunderstormProbability': nightPart['thunderstormProbability'],
        });
      }
      return periods;
    } catch (e) {
      throw Exception('Error in extractForecast: $e');
    }
  }

  Future<List<HourlyForecast>> getHourlyForecast({SDCity? city, double? latitude, double? longitude}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cityKey = city?.name ?? (latitude != null && longitude != null ? '${latitude}_$longitude' : 'default');
      final cacheKey = 'hourlyWeather_${_cacheVersion}_$cityKey';
      final cacheTimeKey = '${cacheKey}_time';
      final now = DateTime.now().millisecondsSinceEpoch;

      final cached = prefs.getString(cacheKey);
      final cachedTime = prefs.getInt(cacheTimeKey);
      if (cached != null && cachedTime != null && now - cachedTime < cacheDurationMs) {
        final List<dynamic> hours = json.decode(cached);
        return hours.map((h) => HourlyForecast.fromJson(h)).toList();
      }

      final double lat = latitude ?? city?.latitude ?? _defaultLatitude;
      final double lon = longitude ?? city?.longitude ?? _defaultLongitude;
      final hourlyUrl = Uri.parse(
        '$_baseUrl/forecast/hours:lookup?location.latitude=$lat&location.longitude=$lon&unitsSystem=IMPERIAL&hours=24&key=${ApiConfig.googleApiKey}',
      );
      final hourlyResponse = await _makeHttpRequest(hourlyUrl);
      if (hourlyResponse.statusCode != 200) {
        throw Exception('Failed to get hourly forecast: ${hourlyResponse.statusCode}');
      }
      final hourlyData = json.decode(hourlyResponse.body);
      final List<dynamic> hours = hourlyData['forecastHours'] ?? [];
      prefs.setString(cacheKey, json.encode(hours));
      prefs.setInt(cacheTimeKey, now);
      return hours.map((h) => HourlyForecast.fromJson(h)).toList();
    } catch (e) {
      throw Exception('Error in getHourlyForecast: $e');
    }
  }

  /// Fetches and sums the last 24 hours of precipitation (in mm and inches) for a city using the Google Weather history API.
  /// Returns null if the API call fails, allowing the app to continue without this data.
  Future<Map<String, double>?> fetch24HourPrecipitationTotal({required double latitude, required double longitude, SDCity? city}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cityKey = city?.name ?? ('${latitude}_$longitude');
      final cacheKey = 'rain24h_${_cacheVersion}_$cityKey';
      final cacheTimeKey = '${cacheKey}_time';
      final now = DateTime.now().millisecondsSinceEpoch;

      final cached = prefs.getString(cacheKey);
      final cachedTime = prefs.getInt(cacheTimeKey);
      if (cached != null && cachedTime != null && now - cachedTime < cacheDurationMs) {
        return Map<String, double>.from(json.decode(cached));
      }

      final url = Uri.parse(
        '$_baseUrl/history/hours:lookup?location.latitude=$latitude&location.longitude=$longitude&unitsSystem=METRIC&hours=24&key=${ApiConfig.googleApiKey}',
      );
      final response = await _makeHttpRequest(url);
      if (response.statusCode != 200) {
        return null;
      }
      final data = json.decode(response.body);
      final List<dynamic> hoursJson = data['historyHours'] ?? [];
      final List<WeatherHistoryHour> hours = parseWeatherHistoryHours(hoursJson);
      double totalMm = 0.0;
      for (final hour in hours) {
        if (hour.precipitationMm != null) {
          totalMm += hour.precipitationMm!;
        }
      }
      // Convert mm to inches
      double totalInches = totalMm / 25.4;
      final result = {'mm': totalMm, 'inches': totalInches};
      prefs.setString(cacheKey, json.encode(result));
      prefs.setInt(cacheTimeKey, now);
      return result;
    } catch (e) {
      return null;
    }
  }
}
