import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for caching location data to reduce API calls and improve performance
class LocationCacheService {
  static const String _cacheKeyPrefix = 'location_cache_';
  static const int _cacheDurationMinutes = 10; // 10 minutes cache duration
  static const int _coordinatePrecision = 4; // Round to 4 decimal places (~11 meters)

  /// Get cached location if available and valid
  static Future<Position?> getCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // First try the default cache key
      Position? cachedLocation = await _getCachedLocationForKey(_getCacheKey());
      
      // If not found, search for any coordinate-based cache keys
      if (cachedLocation == null) {
        final keys = prefs.getKeys();
        for (final key in keys) {
          if (key.startsWith(_cacheKeyPrefix) && key != _getCacheKey()) {
            cachedLocation = await _getCachedLocationForKey(key);
            if (cachedLocation != null) {
              break;
            }
          }
        }
      }
      
      return cachedLocation;
    } catch (e) {
      // If cache is corrupted, remove it
      await _clearCache();
      return null;
    }
  }

  /// Get cached location for a specific key
  static Future<Position?> _getCachedLocationForKey(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData == null) {
        return null;
      }

      final Map<String, dynamic> data = json.decode(cachedData);
      final timestamp = data['timestamp'] as int?;
      
      if (timestamp == null || !_isCacheValid(timestamp)) {
        // Cache is expired, remove it
        await prefs.remove(cacheKey);
        return null;
      }

      // Reconstruct Position object from cached data
      return Position(
        latitude: data['latitude'] as double,
        longitude: data['longitude'] as double,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
        accuracy: data['accuracy'] as double? ?? 0.0,
        altitude: data['altitude'] as double? ?? 0.0,
        heading: data['heading'] as double? ?? 0.0,
        speed: data['speed'] as double? ?? 0.0,
        speedAccuracy: data['speedAccuracy'] as double? ?? 0.0,
        altitudeAccuracy: data['altitudeAccuracy'] as double? ?? 0.0,
        headingAccuracy: data['headingAccuracy'] as double? ?? 0.0,
      );
    } catch (e) {
      // If this specific cache entry is corrupted, remove it
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(cacheKey);
      } catch (_) {}
      return null;
    }
  }

  /// Cache a location with timestamp
  static Future<void> cacheLocation(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey();
      
      final cacheData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': position.timestamp.millisecondsSinceEpoch,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'heading': position.heading,
        'speed': position.speed,
        'speedAccuracy': position.speedAccuracy,
        'altitudeAccuracy': position.altitudeAccuracy,
        'headingAccuracy': position.headingAccuracy,
      };

      await prefs.setString(cacheKey, json.encode(cacheData));
    } catch (e) {
      // Silently fail if caching fails
      // Don't break the app if cache storage fails
    }
  }

  /// Check if cached location is still valid
  static Future<bool> isCacheValid() async {
    final cachedLocation = await getCachedLocation();
    return cachedLocation != null;
  }

  /// Get cache age in minutes
  static Future<int?> getCacheAgeMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // First try the default cache key
      int? age = await _getCacheAgeForKey(_getCacheKey());
      
      // If not found, search for any coordinate-based cache keys
      if (age == null) {
        final keys = prefs.getKeys();
        for (final key in keys) {
          if (key.startsWith(_cacheKeyPrefix) && key != _getCacheKey()) {
            age = await _getCacheAgeForKey(key);
            if (age != null) {
              break;
            }
          }
        }
      }
      
      return age;
    } catch (e) {
      return null;
    }
  }

  /// Get cache age for a specific key
  static Future<int?> _getCacheAgeForKey(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData == null) return null;

      final Map<String, dynamic> data = json.decode(cachedData);
      final timestamp = data['timestamp'] as int?;
      
      if (timestamp == null) return null;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      return now.difference(cacheTime).inMinutes;
    } catch (e) {
      return null;
    }
  }

  /// Clear all location cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_cacheKeyPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // Silently fail if cache clearing fails
    }
  }

  /// Clear specific location cache
  static Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey();
      await prefs.remove(cacheKey);
    } catch (e) {
      // Silently fail if cache clearing fails
    }
  }

  /// Generate cache key based on rounded coordinates
  static String _getCacheKey() {
    // Use a simple default key for initial caching
    return '${_cacheKeyPrefix}current';
  }

  /// Generate cache key for specific coordinates
  static String _getCacheKeyForCoordinates(double latitude, double longitude) {
    // Round coordinates to reduce cache fragmentation
    final roundedLat = _roundCoordinate(latitude);
    final roundedLon = _roundCoordinate(longitude);
    return '$_cacheKeyPrefix${roundedLat}_$roundedLon';
  }

  /// Round coordinate to specified precision
  static double _roundCoordinate(double coordinate) {
    const factor = 10.0 * _coordinatePrecision;
    return (coordinate * factor).round() / factor;
  }

  /// Check if cache timestamp is still valid
  static bool _isCacheValid(int timestamp) {
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(cacheTime);
    return difference.inMinutes < _cacheDurationMinutes;
  }

  /// Update cache key when we have actual coordinates
  static Future<void> updateCacheKey(double latitude, double longitude) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldKey = _getCacheKey();
      final newKey = _getCacheKeyForCoordinates(latitude, longitude);
      
      // If we have data under the old key, move it to the new key
      final oldData = prefs.getString(oldKey);
      if (oldData != null) {
        await prefs.setString(newKey, oldData);
        await prefs.remove(oldKey);
      }
    } catch (e) {
      // Silently fail if cache key update fails
    }
  }
} 