import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/almanac_data.dart';

class AlmanacService {
  static const String _baseUrl = 'https://archive-api.open-meteo.com/v1/archive';
  
  // Cache to prevent repeated API calls
  static final Map<String, AlmanacData> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(hours: 24); // Cache for 24 hours since historical data doesn't change

  /// Fetch historical weather data for a specific location and date
  static Future<AlmanacData> fetchHistoricalData({
    required double latitude,
    required double longitude,
    required DateTime targetDate,
    bool isMetric = false,
  }) async {
    // Create cache key based on location and date
    final cacheKey = '${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}_${targetDate.month}_${targetDate.day}';
    
    // Check if we have cached data that's still valid
    if (_cache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null && DateTime.now().difference(timestamp) < _cacheDuration) {
        return _cache[cacheKey]!;
      }
    }

    final today = DateTime.now();
    final lastYear = today.year - 1;
    final tenYearsAgo = today.year - 10; // Reduced from 20 to 10 years to avoid rate limits
    final startDate = DateFormat('yyyy-MM-dd').format(DateTime(tenYearsAgo, 1, 1));
    final endDate = DateFormat('yyyy-MM-dd').format(DateTime(lastYear, today.month, today.day));
    final tempUnit = isMetric ? 'celsius' : 'fahrenheit';
    final precipUnit = isMetric ? 'mm' : 'inch';

    final uri = Uri.parse(
        '$_baseUrl?latitude=$latitude&longitude=$longitude&start_date=$startDate&end_date=$endDate&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&temperature_unit=$tempUnit&precipitation_unit=$precipUnit&timezone=auto');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded == null || decoded['daily'] == null) {
        throw Exception('No historical weather data found.');
      }
      final data = decoded['daily'];
      
      // Defensive: check required fields
      if (data['time'] == null || 
          data['temperature_2m_max'] == null || 
          data['temperature_2m_min'] == null || 
          data['precipitation_sum'] == null) {
        throw Exception('Incomplete historical weather data.');
      }
      
      final almanacData = _processData(data, targetDate);
      
      // Cache the result
      _cache[cacheKey] = almanacData;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      return almanacData;
    } else if (response.statusCode == 429) {
      // If we hit rate limit, try to return cached data even if expired
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!;
      }
      throw Exception('Rate limit exceeded. Please try again later.');
    } else {
      throw Exception('Failed to load historical weather data. Status: ${response.statusCode}');
    }
  }

  /// Clear the cache (useful for testing or when cache becomes too large)
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  static AlmanacData _processData(Map<String, dynamic> dailyData, DateTime targetDate) {
    final List<String> time = List<String>.from(dailyData['time']);
    final List<dynamic> maxTemps = dailyData['temperature_2m_max'];
    final List<dynamic> minTemps = dailyData['temperature_2m_min'];
    final List<dynamic> precipitations = dailyData['precipitation_sum'];

    double recordHigh = -200;
    int recordHighYear = 0;
    double recordLow = 200;
    int recordLowYear = 0;
    double recordPrecip = 0;
    int recordPrecipYear = 0;
    double highTempSum = 0;
    double lowTempSum = 0;
    double precipSum = 0;
    int count = 0;
    List<YearlyData> recentYearsData = [];
    int minChartYear = targetDate.year - 10;

    // For chart: sum annual precip for each year in the last 10 years
    Map<int, double> annualPrecip = {};
    for (int i = 0; i < time.length; i++) {
      final date = DateTime.parse(time[i]);
      if (date.year >= minChartYear && date.year <= targetDate.year - 1) {
        final double precip = (precipitations[i] != null && precipitations[i] is num) 
            ? (precipitations[i] as num).toDouble() 
            : 0.0;
        annualPrecip[date.year] = (annualPrecip[date.year] ?? 0.0) + precip;
      }
    }

    for (int i = 0; i < time.length; i++) {
      final date = DateTime.parse(time[i]);
      // Filter for target date's month and day across all years
      if (date.month == targetDate.month && date.day == targetDate.day) {
        final double maxTemp = (maxTemps[i] != null && maxTemps[i] is num) 
            ? (maxTemps[i] as num).toDouble() 
            : double.nan;
        final double minTemp = (minTemps[i] != null && minTemps[i] is num) 
            ? (minTemps[i] as num).toDouble() 
            : double.nan;
        final double precip = (precipitations[i] != null && precipitations[i] is num) 
            ? (precipitations[i] as num).toDouble() 
            : double.nan;

        if (!maxTemp.isNaN && maxTemp > recordHigh) {
          recordHigh = maxTemp;
          recordHighYear = date.year;
        }
        if (!minTemp.isNaN && minTemp < recordLow) {
          recordLow = minTemp;
          recordLowYear = date.year;
        }
        if (!precip.isNaN && precip > recordPrecip) {
          recordPrecip = precip;
          recordPrecipYear = date.year;
        }

        if (!maxTemp.isNaN) highTempSum += maxTemp;
        if (!minTemp.isNaN) lowTempSum += minTemp;
        if (!precip.isNaN) precipSum += precip;
        count++;

        // Only add years within the last 10 years for the chart and if precip is a valid number
        if (date.year >= minChartYear && !precip.isNaN) {
          recentYearsData.removeWhere((y) => y.year == date.year); // avoid duplicates
          recentYearsData.add(YearlyData(
            year: date.year,
            highTemp: maxTemp,
            lowTemp: minTemp,
            precip: precip,
          ));
        }
      }
    }
    
    if (count == 0) {
      throw Exception('No historical data could be found for this date in the past 20 years.');
    }

    // Sort recent years data descending
    recentYearsData.sort((a, b) => b.year.compareTo(a.year));

    return AlmanacData(
      recordHighTemp: recordHigh,
      recordHighYear: recordHighYear,
      recordLowTemp: recordLow,
      recordLowYear: recordLowYear,
      recordPrecip: recordPrecip,
      recordPrecipYear: recordPrecipYear,
      averageHigh: highTempSum / count,
      averageLow: lowTempSum / count,
      averagePrecipitation: precipSum / count,
      recentYears: recentYearsData,
    );
  }
} 