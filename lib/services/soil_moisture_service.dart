import 'package:http/http.dart' as http;

/// Service for fetching NASA SPoRT soil moisture data for the Dakotas region
class SoilMoistureService {
  static const String _baseUrl = 'https://weather.ndc.nasa.gov/sport/dynamic/lis_DAKOTAS';
  
  /// Get soil moisture URL for a specific depth
  String getSoilMoistureUrl(String depth) {
    final now = DateTime.now().toUtc();
    final date = "${now.year.toString().padLeft(4, '0')}"
                 "${now.month.toString().padLeft(2, '0')}"
                 "${now.day.toString().padLeft(2, '0')}";
    return "$_baseUrl/vsm${depth}percent_${date}_00z_dakotas.gif";
  }

  /// Get soil moisture URL for yesterday (fallback)
  String getYesterdaySoilMoistureUrl(String depth) {
    final yesterday = DateTime.now().toUtc().subtract(const Duration(days: 1));
    final date = "${yesterday.year.toString().padLeft(4, '0')}"
                 "${yesterday.month.toString().padLeft(2, '0')}"
                 "${yesterday.day.toString().padLeft(2, '0')}";
    return "$_baseUrl/vsm${depth}percent_${date}_00z_dakotas.gif";
  }

  /// Check if an image URL is accessible
  Future<bool> isImageAccessible(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get the best available soil moisture URL (today's or yesterday's)
  Future<String> getBestSoilMoistureUrl(String depth) async {
    final todayUrl = getSoilMoistureUrl(depth);
    final isTodayAvailable = await isImageAccessible(todayUrl);
    
    if (isTodayAvailable) {
      return todayUrl;
    } else {
      return getYesterdaySoilMoistureUrl(depth);
    }
  }

  /// Get all soil moisture URLs for the three depths
  Future<Map<String, String>> getAllSoilMoistureUrls() async {
    final depths = ['0-10', '0-40', '0-100'];
    final urls = <String, String>{};
    
    for (final depth in depths) {
      urls[depth] = await getBestSoilMoistureUrl(depth);
    }
    
    return urls;
  }

  /// Get the NASA SPoRT website URL
  String getWebsiteUrl() {
    return 'https://weather.ndc.nasa.gov/sport/case_studies/lis_DAKOTAS.html';
  }
} 