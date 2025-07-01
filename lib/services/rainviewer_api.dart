import 'dart:convert';
import 'package:http/http.dart' as http;

/// Data class for the entire RainViewer API response.
class RainviewerData {
  final String? host;
  final List<RadarFrameInfo> past;
  final List<RadarFrameInfo> nowcast;

  RainviewerData({this.host, required this.past, required this.nowcast});

  /// Creates a [RainviewerData] object from a JSON map.
  factory RainviewerData.fromJson(Map<String, dynamic> json) {
    final radarData = json['radar'] as Map<String, dynamic>?;
    final pastData = radarData?['past'] as List<dynamic>? ?? [];
    final nowcastData = radarData?['nowcast'] as List<dynamic>? ?? [];

    return RainviewerData(
      host: json["host"] as String?,
      past: pastData
          .map((x) => RadarFrameInfo.fromJson(x as Map<String, dynamic>))
          .toList(),
      nowcast: nowcastData
          .map((x) => RadarFrameInfo.fromJson(x as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Data class for a single radar frame.
class RadarFrameInfo {
  final int time;
  final String path;

  RadarFrameInfo({required this.time, required this.path});

  /// Creates a [RadarFrameInfo] object from a JSON map.
  factory RadarFrameInfo.fromJson(Map<String, dynamic> json) =>
      RadarFrameInfo(time: json["time"] as int, path: json["path"] as String);
}

/// A utility class for interacting with the RainViewer API.
class RainViewerApi {
  static const String apiUrl =
      'https://api.rainviewer.com/public/weather-maps.json';

  /// Fetches the latest radar data from the RainViewer API.
  ///
  /// Returns a [RainviewerData] object on success, or throws an exception on failure.
  static Future<RainviewerData> fetchRadarData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return RainviewerData.fromJson(data);
      } else {
        throw Exception('Failed to load radar data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching radar data: $e');
    }
  }
}
