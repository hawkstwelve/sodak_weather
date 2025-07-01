import 'package:flutter/material.dart';
import '../models/notification_preferences.dart';
import '../models/sd_city.dart';
import '../services/backend_service.dart';

class NotificationPreferencesProvider extends ChangeNotifier {
  NotificationPreferences? _preferences;
  bool _loading = false;
  String? _error;
  final BackendService _backendService = BackendService();

  NotificationPreferences? get preferences => _preferences;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadPreferences() async {
    _loading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Load from Firestore via BackendService
      final prefs = await _backendService.loadNotificationPreferences();
      if (prefs != null) {
        _preferences = prefs;
      } else {
        // Create default preferences immediately
        _preferences = NotificationPreferences(
          enabledAlertTypes: [
            "Air Quality Alert",
            "Air Stagnation Advisory",
            "Blizzard Warning",
            "Blowing Dust Advisory",
            "Blowing Dust Warning",
            "Brisk Wind Advisory",
            "Cold Weather Advisory",
            "Dense Fog Advisory",
            "Dense Smoke Advisory",
            "Dust Advisory",
            "Dust Storm Warning",
            "Evacuation Immediate",
            "Extreme Heat Warning",
            "Extreme Heat Watch",
            "Extreme Cold Warning",
            "Extreme Cold Watch",
            "Extreme Fire Danger",
            "Extreme Wind Warning",
            "Fire Warning",
            "Fire Weather Watch",
            "Flash Flood Statement",
            "Flash Flood Warning",
            "Flash Flood Watch",
            "Flood Advisory",
            "Flood Statement",
            "Flood Warning",
            "Flood Watch",
            "Freeze Warning",
            "Freeze Watch",
            "Freezing Fog Advisory",
            "Frost Advisory",
            "Heat Advisory",
            "High Wind Warning",
            "High Wind Watch",
            "Ice Storm Warning",
            "Law Enforcement Warning",
            "Local Area Emergency",
            "Red Flag Warning",
            "Severe Thunderstorm Warning",
            "Severe Thunderstorm Watch",
            "Severe Weather Statement",
            "Shelter In Place Warning",
            "Snow Squall Warning",
            "Special Weather Statement",
            "Tornado Warning",
            "Tornado Watch",
            "Wind Advisory",
            "Winter Storm Warning",
            "Winter Storm Watch",
            "Winter Weather Advisory"
          ],
          doNotDisturb: null,
          lastUpdated: DateTime.now(),
        );
        // Save the default preferences to backend
        await savePreferences(_preferences!);
      }
    } catch (e) {
      _error = e.toString();
      // Fallback to default preferences on error
      _preferences = NotificationPreferences(
        enabledAlertTypes: [
          "Air Quality Alert",
          "Air Stagnation Advisory",
          "Blizzard Warning",
          "Blowing Dust Advisory",
          "Blowing Dust Warning",
          "Brisk Wind Advisory",
          "Cold Weather Advisory",
          "Dense Fog Advisory",
          "Dense Smoke Advisory",
          "Dust Advisory",
          "Dust Storm Warning",
          "Evacuation Immediate",
          "Extreme Heat Warning",
          "Extreme Heat Watch",
          "Extreme Cold Warning",
          "Extreme Cold Watch",
          "Extreme Fire Danger",
          "Extreme Wind Warning",
          "Fire Warning",
          "Fire Weather Watch",
          "Flash Flood Statement",
          "Flash Flood Warning",
          "Flash Flood Watch",
          "Flood Advisory",
          "Flood Statement",
          "Flood Warning",
          "Flood Watch",
          "Freeze Warning",
          "Freeze Watch",
          "Freezing Fog Advisory",
          "Frost Advisory",
          "Heat Advisory",
          "High Wind Warning",
          "High Wind Watch",
          "Ice Storm Warning",
          "Law Enforcement Warning",
          "Local Area Emergency",
          "Red Flag Warning",
          "Severe Thunderstorm Warning",
          "Severe Thunderstorm Watch",
          "Severe Weather Statement",
          "Shelter In Place Warning",
          "Snow Squall Warning",
          "Special Weather Statement",
          "Tornado Warning",
          "Tornado Watch",
          "Wind Advisory",
          "Winter Storm Warning",
          "Winter Storm Watch",
          "Winter Weather Advisory"
        ],
        doNotDisturb: null,
        lastUpdated: DateTime.now(),
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> savePreferences(NotificationPreferences prefs) async {
    _loading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Store in Firestore via BackendService
      final success = await _backendService.storeNotificationPreferences(prefs);
      if (success) {
        _preferences = prefs;
      } else {
        _error = 'Failed to save preferences to backend';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateEnabledAlertTypes(List<String> types) async {
    if (_preferences == null) return;
    
    final updated = NotificationPreferences(
      enabledAlertTypes: types,
      doNotDisturb: _preferences!.doNotDisturb,
      lastUpdated: DateTime.now(),
    );
    await savePreferences(updated);
  }

  Future<void> updateDoNotDisturb(DoNotDisturb? doNotDisturb) async {
    if (_preferences == null) return;
    
    final updated = NotificationPreferences(
      enabledAlertTypes: _preferences!.enabledAlertTypes,
      doNotDisturb: doNotDisturb,
      lastUpdated: DateTime.now(),
    );
    await savePreferences(updated);
  }

  /// Sync current location with backend
  Future<void> syncLocationWithBackend({
    required double lat,
    required double lon,
    required bool isUsingLocation,
    required String? selectedCity,
  }) async {
    try {
      await _backendService.updateUserLocation(
        lat: lat,
        lon: lon,
        isUsingLocation: isUsingLocation,
        selectedCity: selectedCity != null ? SDCity(name: selectedCity, latitude: lat, longitude: lon, nwsOffice: '') : null,
      );
    } catch (e) {
      // Handle error silently
    }
  }

  /// Sync FCM token with backend
  Future<void> syncFcmTokenWithBackend(String fcmToken) async {
    try {
      await _backendService.updateFcmToken(fcmToken);
    } catch (e) {
      // Handle error silently
    }
  }
} 