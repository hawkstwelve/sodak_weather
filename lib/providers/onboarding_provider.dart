import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider to manage onboarding state and completion
class OnboardingProvider with ChangeNotifier {
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _locationPermissionRequestedKey = 'location_permission_requested';
  static const String _notificationPermissionRequestedKey = 'notification_permission_requested';
  
  bool _isComplete = false;
  bool _locationPermissionRequested = false;
  bool _notificationPermissionRequested = false;
  bool _isLoading = false;

  bool get isComplete => _isComplete;
  bool get locationPermissionRequested => _locationPermissionRequested;
  bool get notificationPermissionRequested => _notificationPermissionRequested;
  bool get isLoading => _isLoading;

  /// Initialize the provider and load saved state
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _isComplete = prefs.getBool(_onboardingCompleteKey) ?? false;
      _locationPermissionRequested = prefs.getBool(_locationPermissionRequestedKey) ?? false;
      _notificationPermissionRequested = prefs.getBool(_notificationPermissionRequestedKey) ?? false;
    } catch (e) {
      // If there's an error loading preferences, assume onboarding is not complete
      // This is especially important for release builds where errors might be handled differently
      _isComplete = false;
      _locationPermissionRequested = false;
      _notificationPermissionRequested = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark onboarding as complete
  Future<void> markComplete() async {
    if (_isComplete) return;

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompleteKey, true);
      _isComplete = true;
    } catch (e) {
      // Handle error silently - onboarding will show again on next app launch
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark location permission as requested
  Future<void> markLocationPermissionRequested() async {
    if (_locationPermissionRequested) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_locationPermissionRequestedKey, true);
      _locationPermissionRequested = true;
      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }

  /// Mark notification permission as requested
  Future<void> markNotificationPermissionRequested() async {
    if (_notificationPermissionRequested) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationPermissionRequestedKey, true);
      _notificationPermissionRequested = true;
      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }

  /// Reset onboarding state (useful for testing or user preference)
  Future<void> resetOnboarding() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompleteKey);
      await prefs.remove(_locationPermissionRequestedKey);
      await prefs.remove(_notificationPermissionRequestedKey);
      
      _isComplete = false;
      _locationPermissionRequested = false;
      _notificationPermissionRequested = false;
    } catch (e) {
      // Handle error silently
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 