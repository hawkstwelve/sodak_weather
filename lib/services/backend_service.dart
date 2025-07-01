import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_preferences.dart';
import '../models/sd_city.dart';
import '../models/notification_history.dart';

class BackendService {
  static const String _baseUrl = 'https://us-central1-sodak-weather-app.cloudfunctions.net';
  static String? _userId;

  static void setUserId(String userId) {
    _userId = userId;
  }

  /// Get or create a unique user ID for this device
  static Future<String> getUserId() async {
    if (_userId != null) return _userId!;
    
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    
    if (_userId == null) {
      // Generate a new user ID
      _userId = _generateUserId();
      await prefs.setString('user_id', _userId!);
    }
    
    return _userId!;
  }

  /// Generate a unique user ID
  static String _generateUserId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return 'user_${List.generate(16, (index) => chars[random.nextInt(chars.length)]).join()}';
  }

  /// Update user's location context on the backend
  Future<bool> updateUserLocation({
    required double lat,
    required double lon,
    required bool isUsingLocation,
    required SDCity? selectedCity,
  }) async {
    final userId = await BackendService.getUserId();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/updateUserLocation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'location': {
            'lat': lat,
            'lon': lon,
            'isUsingLocation': isUsingLocation,
            'selectedCity': selectedCity != null ? {
              'name': selectedCity.name,
              'latitude': selectedCity.latitude,
              'longitude': selectedCity.longitude,
              'nwsOffice': selectedCity.nwsOffice,
            } : null,
          },
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Update user's FCM token on the backend
  Future<bool> updateFcmToken(String fcmToken) async {
    final userId = await BackendService.getUserId();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/updateFcmToken'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'fcmToken': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Store notification preferences in Firestore
  Future<bool> storeNotificationPreferences(NotificationPreferences preferences) async {
    final userId = await BackendService.getUserId();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/storeNotificationPreferences'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'preferences': preferences.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Load notification preferences from Firestore
  Future<NotificationPreferences?> loadNotificationPreferences() async {
    final userId = await BackendService.getUserId();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/loadNotificationPreferences?userId=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null) {
          return NotificationPreferences.fromJson(data);
        }
        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Get notification history for the user
  Future<List<NotificationHistory>> loadNotificationHistory() async {
    final userId = await BackendService.getUserId();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/loadNotificationHistory?userId=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) => NotificationHistory.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
} 