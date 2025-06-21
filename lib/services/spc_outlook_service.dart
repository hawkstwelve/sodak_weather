import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/spc_outlook.dart';

/// A service class to handle fetching outlook data from the Storm Prediction Center (SPC).
class SpcOutlookService {
  static final List<int> _days = [1, 2, 3];

  /// Fetches all outlooks for days 1, 2, and 3.
  ///
  /// This method uses a cache to avoid redundant network calls.
  static Future<List<SpcOutlook>> fetchAllOutlooks() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    List<SpcOutlook> results = [];

    for (final day in _days) {
      final cacheKey = 'spc_outlook_day$day';
      final cacheTimeKey = 'spc_outlook_day${day}_time';
      final cached = prefs.getString(cacheKey);
      final cachedTime = prefs.getInt(cacheTimeKey);

      if (cached != null &&
          cachedTime != null &&
          now.millisecondsSinceEpoch - cachedTime < 3600000) { // 1 hour cache
        results.add(SpcOutlook.fromJson(jsonDecode(cached)));
      } else {
        final data = await _fetchOutlook(day);
        prefs.setString(cacheKey, jsonEncode(data.toJson()));
        prefs.setInt(cacheTimeKey, now.millisecondsSinceEpoch);
        results.add(data);
      }
    }
    return results;
  }

  /// Fetches a single outlook from the SPC website.
  static Future<SpcOutlook> _fetchOutlook(int day) async {
    final imgUrl = 'https://www.spc.noaa.gov/products/outlook/day${day}otlk.gif';
    final txtUrl = 'https://www.spc.noaa.gov/products/outlook/day${day}otlk.txt';
    String discussion = '';

    try {
      final resp = await http.get(
        Uri.parse(txtUrl),
        headers: {'User-Agent': 'Sodak Weather App v1.0'},
      );
      if (resp.statusCode == 200) {
        discussion = resp.body.trim();
      }
    } catch (e) {
      // Ignore errors for the text file, the image is the primary content.
    }
    return SpcOutlook(day: day, imgUrl: imgUrl, discussion: discussion);
  }

  /// Clears the SPC cache. This can be called to force a refresh.
  static Future<void> clearSpcCache() async {
    final prefs = await SharedPreferences.getInstance();
    for (final day in _days) {
      await prefs.remove('spc_outlook_day$day');
      await prefs.remove('spc_outlook_day${day}_time');
    }
  }
} 