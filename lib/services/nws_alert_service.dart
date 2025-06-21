import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/nws_alert_model.dart';
import '../models/sd_city.dart';
import 'dart:convert';

class NwsAlertService {
  static const String baseUrl = 'https://api.weather.gov/alerts/active';
  static const int cacheDurationMs = 10 * 60 * 1000; // 10 minutes

  // Fetch alerts for a given city (by lat/lon) with persistent cache
  static Future<NwsAlertCollection?> fetchAlertsForCity(SDCity city) async {
    final prefs = await SharedPreferences.getInstance();
    final cityKey = city.name;
    final cacheKey = 'nwsAlerts_$cityKey';
    final cacheTimeKey = '${cacheKey}_time';
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check cache
    final cached = prefs.getString(cacheKey);
    final cachedTime = prefs.getInt(cacheTimeKey);
    if (cached != null && cachedTime != null && now - cachedTime < cacheDurationMs) {
      return nwsAlertCollectionFromJson(cached);
    }

    final url = Uri.parse('$baseUrl?point=${city.latitude},${city.longitude}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      prefs.setString(cacheKey, response.body);
      prefs.setInt(cacheTimeKey, now);
      return nwsAlertCollectionFromJson(response.body);
    }
    return null;
  }

  // Fetch alerts for all SD cities in parallel for better performance, with persistent cache
  static Future<List<NwsAlertFeature>> fetchAllSdcityAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'nwsAlerts_allCities';
    final cacheTimeKey = '${cacheKey}_time';
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check cache
    final cached = prefs.getString(cacheKey);
    final cachedTime = prefs.getInt(cacheTimeKey);
    if (cached != null && cachedTime != null && now - cachedTime < cacheDurationMs) {
      final List<dynamic> featuresJson = json.decode(cached);
      return featuresJson.map((f) => NwsAlertFeature.fromJson(f)).toList();
    }

    // Create a list of futures for all city alert requests
    final futures = SDCities.allCities.map((city) => fetchAlertsForCity(city));
    // Execute all requests in parallel
    final results = await Future.wait(futures);
    // Collect all alerts from successful responses
    List<NwsAlertFeature> allAlerts = [];
    for (final collection in results) {
      if (collection?.features != null && collection!.features!.isNotEmpty) {
        allAlerts.addAll(collection.features!);
      }
    }
    // Store in cache
    prefs.setString(cacheKey, json.encode(allAlerts.map((f) => f.toJson()).toList()));
    prefs.setInt(cacheTimeKey, now);
    return allAlerts;
  }
}
