import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../providers/notification_preferences_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/location_provider.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  FirebaseMessaging get messaging => _messaging;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Example: store the latest notification (expand as needed)
  RemoteMessage? _latestMessage;
  RemoteMessage? get latestMessage => _latestMessage;

  NotificationPreferencesProvider? _preferencesProvider;
  WeatherProvider? _weatherProvider;
  LocationProvider? _locationProvider;

  NotificationService() {
    // Don't initialize here - Firebase should be initialized in main.dart first
  }

  // Call this method after Firebase is initialized
  Future<void> initialize() async {
    // await requestPermissions(); // Do not request permissions automatically
    await _getFcmToken();
    _setupMessageHandlers();
  }

  // Set providers for location syncing
  void setProviders({
    required NotificationPreferencesProvider preferencesProvider,
    required WeatherProvider weatherProvider,
    required LocationProvider locationProvider,
  }) {
    _preferencesProvider = preferencesProvider;
    _weatherProvider = weatherProvider;
    _locationProvider = locationProvider;
  }

  Future<void> requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  Future<void> _getFcmToken() async {
    _fcmToken = await _messaging.getToken();
    notifyListeners();
    
    // Sync FCM token with backend
    if (_fcmToken != null && _preferencesProvider != null) {
      try {
        await _preferencesProvider!.syncFcmTokenWithBackend(_fcmToken!);
      } catch (e) {
        // Error syncing FCM token
      }
    }
    
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      notifyListeners();
      
      // Sync new token with backend
      if (_preferencesProvider != null) {
        _preferencesProvider!.syncFcmTokenWithBackend(newToken);
      }
    });
  }

  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _latestMessage = message;
      notifyListeners();
      
      // Handle the message (you can show a local notification here)
      _handleForegroundMessage(message);
    });

    // Handle background messages (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _latestMessage = message;
      notifyListeners();
      
      // Handle notification tap when app is in background
      _handleNotificationTap(message);
    });

    // Handle notification tap when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _latestMessage = message;
        notifyListeners();
        
        // Handle notification tap when app was terminated
        _handleNotificationTap(message);
      }
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Store notification data for potential use
    _latestMessage = message;
    notifyListeners();
    
    // Note: For foreground messages, FCM will not show a system notification
    // by default. The user will see this in the app logs.
    // In a production app, you might want to show an in-app notification
    // or use a different approach for foreground notifications.
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Handle notification tap - could navigate to relevant screen
    // This would typically use a navigation service or callback
  }

  /// Sync current location context with backend
  Future<void> syncLocationWithBackend() async {
    if (_preferencesProvider == null || _weatherProvider == null) return;

    try {
      double lat, lon;
      bool isUsingLocation;
      String? selectedCity;

      if (_weatherProvider!.isUsingLocation && _locationProvider?.currentLocation != null) {
        // Using GPS location
        lat = _locationProvider!.currentLocation!.latitude;
        lon = _locationProvider!.currentLocation!.longitude;
        isUsingLocation = true;
        selectedCity = null;
      } else {
        // Using selected city
        final city = _weatherProvider!.selectedCity;
        lat = city.latitude;
        lon = city.longitude;
        isUsingLocation = false;
        selectedCity = city.name;
      }

      await _preferencesProvider!.syncLocationWithBackend(
        lat: lat,
        lon: lon,
        isUsingLocation: isUsingLocation,
        selectedCity: selectedCity,
      );
    } catch (e) {
      // Error syncing location
    }
  }

  /// Call this when location changes (GPS or selected city)
  Future<void> onLocationChanged() async {
    await syncLocationWithBackend();
  }


  // Expose a method to manually refresh the FCM token if needed
  Future<void> refreshFcmToken() async {
    await _getFcmToken();
  }
} 