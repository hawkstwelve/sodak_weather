import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/location_cache_service.dart';
import 'dart:async';

/// Enum for different location error types
enum LocationErrorType {
  permissionDenied,
  permissionDeniedForever,
  locationServicesDisabled,
  locationTimeout,
  networkError,
  unknown,
}

/// Provider for managing location-related state
class LocationProvider with ChangeNotifier {
  Position? _currentLocation;
  LocationPermission _permissionStatus = LocationPermission.denied;
  bool _isLoading = false;
  String? _errorMessage;
  LocationErrorType? _errorType;
  bool _hasRequestedPermission = false;
  bool _isUsingCachedLocation = false;
  int? _cacheAgeMinutes;
  final Completer<void> _initializationCompleter = Completer<void>();
  Future<void> get initializationDone => _initializationCompleter.future;

  // Getters
  Position? get currentLocation => _currentLocation;
  LocationPermission get permissionStatus => _permissionStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LocationErrorType? get errorType => _errorType;
  bool get hasLocation => _currentLocation != null;
  bool get hasRequestedPermission => _hasRequestedPermission;
  bool get isPermissionDenied => _permissionStatus == LocationPermission.denied;
  bool get isPermissionDeniedForever => _permissionStatus == LocationPermission.deniedForever;
  bool get isLocationServicesDisabled => _permissionStatus == LocationPermission.unableToDetermine;
  bool get isUsingCachedLocation => _isUsingCachedLocation;
  int? get cacheAgeMinutes => _cacheAgeMinutes;

  /// Initialize the location provider
  LocationProvider() {
    _initializeLocation();
  }

  /// Initialize location services and check permissions
  Future<void> _initializeLocation() async {
    try {
      _permissionStatus = await LocationService.checkPermission();
      
      // Try to load cached location on initialization
      await _loadCachedLocation();
      
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.complete();
      }
    } catch (e) {
      // In release builds, ensure initialization completes even if there are errors
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.complete();
      }
    } finally {
      notifyListeners();
    }
  }

  /// Load cached location if available
  Future<void> _loadCachedLocation() async {
    try {
      final cachedLocation = await LocationCacheService.getCachedLocation();
      if (cachedLocation != null) {
        _currentLocation = cachedLocation;
        _isUsingCachedLocation = true;
        _cacheAgeMinutes = await LocationCacheService.getCacheAgeMinutes();
        _errorMessage = null;
        _errorType = null;
      }
    } catch (e) {
      // Silently fail if cache loading fails
    }
  }

  /// Get the current location with enhanced error handling and caching
  Future<bool> getCurrentLocation({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    _errorType = null;
    _isUsingCachedLocation = false;
    notifyListeners();

    try {
      // Check cache first (unless forcing refresh)
      if (!forceRefresh) {
        final cachedLocation = await LocationCacheService.getCachedLocation();
        if (cachedLocation != null) {
          _currentLocation = cachedLocation;
          _isUsingCachedLocation = true;
          _cacheAgeMinutes = await LocationCacheService.getCacheAgeMinutes();
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      // Check if location services are enabled
      bool serviceEnabled = await LocationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorType = LocationErrorType.locationServicesDisabled;
        _errorMessage = 'Location services are disabled. Please enable GPS in your device settings.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Always check permission status fresh to handle cases where user granted permissions
      LocationPermission permission = await LocationService.checkPermission();
      
      // Update the stored permission status
      _permissionStatus = permission;
      
      if (permission == LocationPermission.denied) {
        _hasRequestedPermission = true;
        permission = await LocationService.requestPermission();
        
        // Update permission status again after request
        _permissionStatus = permission;
        
        if (permission == LocationPermission.denied) {
          _errorType = LocationErrorType.permissionDenied;
          _errorMessage = 'Location permission denied. Please enable location access in settings.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorType = LocationErrorType.permissionDeniedForever;
        _errorMessage = 'Location permission permanently denied. Please enable location access in device settings.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final position = await LocationService.getCurrentLocation();
      
      if (position != null) {
        _currentLocation = position;
        _permissionStatus = await LocationService.checkPermission();
        _errorMessage = null;
        _errorType = null;
        _isUsingCachedLocation = false;
        _cacheAgeMinutes = 0;
        
        // Cache the new location
        await LocationCacheService.cacheLocation(position);
        
        // Update cache key with actual coordinates
        await LocationCacheService.updateCacheKey(position.latitude, position.longitude);
      } else {
        _errorType = LocationErrorType.locationTimeout;
        _errorMessage = 'Location request timed out. Please try again.';
      }
    } catch (e) {
      _errorType = LocationErrorType.unknown;
      _errorMessage = 'Error getting location: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _currentLocation != null;
  }

  /// Force refresh location (bypass cache)
  Future<bool> refreshLocation() async {
    return await getCurrentLocation(forceRefresh: true);
  }

  /// Clear the current location and errors
  void clearLocation() {
    _currentLocation = null;
    _errorMessage = null;
    _errorType = null;
    _isUsingCachedLocation = false;
    _cacheAgeMinutes = null;
    notifyListeners();
  }

  /// Clear location cache
  Future<void> clearCache() async {
    await LocationCacheService.clearCache();
    _isUsingCachedLocation = false;
    _cacheAgeMinutes = null;
    notifyListeners();
  }

  /// Refresh permission status from the system
  Future<void> refreshPermissionStatus() async {
    _permissionStatus = await LocationService.checkPermission();
    notifyListeners();
  }

  /// Check and update permission status
  Future<void> checkPermissionStatus() async {
    _permissionStatus = await LocationService.checkPermission();
    notifyListeners();
  }

  /// Request location permission
  Future<void> requestPermission() async {
    _hasRequestedPermission = true;
    _permissionStatus = await LocationService.requestPermission();
    notifyListeners();
  }

  /// Clear error state
  void clearError() {
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }

  /// Get user-friendly error message based on error type
  String get userFriendlyErrorMessage {
    switch (_errorType) {
      case LocationErrorType.permissionDenied:
        return 'Location permission denied. Please enable location access in settings.';
      case LocationErrorType.permissionDeniedForever:
        return 'Location permission permanently denied. Please enable location access in device settings.';
      case LocationErrorType.locationServicesDisabled:
        return 'Location services are disabled. Please enable GPS in your device settings.';
      case LocationErrorType.locationTimeout:
        return 'Location request timed out. Please try again.';
      case LocationErrorType.networkError:
        return 'Network error while getting location. Please check your connection.';
      case LocationErrorType.unknown:
        return _errorMessage ?? 'Unknown error occurred while getting location.';
      case null:
        return '';
    }
  }

  /// Get suggested action based on error type
  String get suggestedAction {
    switch (_errorType) {
      case LocationErrorType.permissionDenied:
      case LocationErrorType.permissionDeniedForever:
        return 'Open Settings';
      case LocationErrorType.locationServicesDisabled:
        return 'Enable Location Services';
      case LocationErrorType.locationTimeout:
      case LocationErrorType.networkError:
      case LocationErrorType.unknown:
        return 'Try Again';
      case null:
        return '';
    }
  }

  /// Get cache status message
  String get cacheStatusMessage {
    if (_isUsingCachedLocation && _cacheAgeMinutes != null) {
      String message;
      if (_cacheAgeMinutes! < 1) {
        message = 'Using recent location data';
      } else if (_cacheAgeMinutes! < 5) {
        message = 'Using location data from $_cacheAgeMinutes minutes ago';
      } else {
        message = 'Using cached location data ($_cacheAgeMinutes minutes old)';
      }
      return message;
    }
    return '';
  }
} 